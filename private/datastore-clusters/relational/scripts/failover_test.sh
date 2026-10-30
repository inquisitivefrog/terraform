#!/usr/bin/env bash
# Take out a cluster's writer and measure what an application sees: a probe
# pod (in another zone) writes through the writer endpoint once a second;
# each failed write is a second of write outage.
# Usage: private/datastore-clusters/relational/scripts/failover_test.sh pg|mysql [pod|zone] [dev]
#   pod   (default) delete the writer's pod, as a crash or eviction would
#   zone  stop the writer's whole node container: a zone losing power. The
#         node comes back at the end and the test waits for the cluster to
#         heal, reporting how long the rejoin took.
# This changes the cluster (another node usually becomes the writer; a
# PostgreSQL primary that is back within failoverDelay keeps its role).
# Nothing committed is lost: PostgreSQL commits wait for a replica, Galera
# for a majority. The probe table is dropped at the end.
# zone fails if the cluster has not healed 10 minutes after the zone is
# back. runbook_26_zone.sh runs it under k6 load and judges the RTO.
# The last line is for runbook_24_writer.sh: RESULT start=<epoch>
# first_fail=<epoch|-> last_fail=<epoch|-> writer=<old>-><new|same>

set -uo pipefail
source "$(dirname "$0")/../../../scripts/private_env.sh" # use_cluster, k, CTX

ENGINE="${1:-}"
MODE="${2:-pod}"
ENV="${3:-dev}"
[[ "$ENGINE" =~ ^(pg|mysql)$ && "$MODE" =~ ^(pod|zone)$ ]] || {
  echo "Usage: $0 pg|mysql [pod|zone] [dev]" >&2
  exit 1
}
NS="relational"
PROBE="failover-probe"
use_cluster "datastore-$ENV"

zone_of_pod() { k get node "$(k -n "$NS" get pod "$1" -o jsonpath='{.spec.nodeName}')" -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'; }
node_of_pod() { k -n "$NS" get pod "$1" -o jsonpath='{.spec.nodeName}'; }
probe_exec() { k -n "$NS" exec "$PROBE" -- sh -c "$1"; }

if [[ "$ENGINE" == "pg" ]]; then
  CR="clusters.postgresql.cnpg.io/pg"
  IMAGE="$(k -n "$NS" get "$CR" -o jsonpath='{.spec.imageName}')"
  healthy() { [[ "$(k -n "$NS" get "$CR" -o jsonpath='{.status.phase}')" == "Cluster in healthy state" ]]; }
  MEMBERS="cnpg.io/cluster=pg"
  writer() { k -n "$NS" get "$CR" -o jsonpath='{.status.currentPrimary}'; }
  SECRET_NAME="pg-app" SECRET_KEY="password" PW_ENV="PGPASSWORD"
  # statement_timeout: a write must not hang on a dead primary
  CLIENT='psql -XAtq "host=pg-rw user=app dbname=appdb sslmode=require connect_timeout=2 options=-cstatement_timeout=3000" -c'
  SETUP="create table if not exists failover_probe (id bigserial primary key, ts timestamptz not null default now())"
  WRITE="insert into failover_probe default values"
else
  CR="perconaxtradbclusters.pxc.percona.com/mysql"
  IMAGE="$(k -n "$NS" get "$CR" -o jsonpath='{.spec.pxc.image}')"
  healthy() { [[ "$(k -n "$NS" get "$CR" -o jsonpath='{.status.state}')" == "ready" ]]; }
  MEMBERS="app.kubernetes.io/instance=mysql,app.kubernetes.io/component=pxc"
  writer() { probe_exec "$CLIENT 'select @@hostname'" 2>/dev/null; }
  SECRET_NAME="mysql-secrets" SECRET_KEY="root" PW_ENV="MYSQL_PWD"
  CLIENT='timeout 5 mysql -uroot -h mysql-haproxy --ssl-mode=REQUIRED --connect-timeout=2 -NBe'
  # Galera requires a primary key on every table it replicates
  SETUP="create database if not exists probe; create table if not exists probe.failover_probe (id bigint auto_increment primary key, ts timestamp(3) not null default current_timestamp(3))"
  WRITE="insert into probe.failover_probe () values ()"
fi

healthy || {
  echo "$CR is not healthy; run check_resources.sh first." >&2
  exit 1
}

# The writer before the test. For MySQL it is whichever node HAProxy sends
# writes to, so the probe has to exist to ask; start it outside no zone yet.
OLD_POD="$([[ "$ENGINE" == "pg" ]] && writer)"
AVOID_ZONE="$([[ -n "$OLD_POD" ]] && zone_of_pod "$OLD_POD")"

start_probe() {
  local affinity=""
  [[ -n "$1" ]] && affinity="
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - {key: topology.kubernetes.io/zone, operator: NotIn, values: [\"$1\"]}"
  k -n "$NS" apply -f - >/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $PROBE
  labels: {app: $PROBE}
spec:
  restartPolicy: Never
  terminationGracePeriodSeconds: 1$affinity
  containers:
    - name: probe
      image: $IMAGE
      env:
        - name: $PW_ENV
          valueFrom: {secretKeyRef: {name: $SECRET_NAME, key: $SECRET_KEY}}
      command: [sh, -c, "sleep infinity"]
      resources:
        requests: {cpu: 50m, memory: 64Mi}
EOF
  k -n "$NS" wait --for=condition=Ready "pod/$PROBE" --timeout=120s >/dev/null
}

STOPPED_NODE=""
cleanup() {
  if [[ -n "$STOPPED_NODE" ]]; then
    echo "$(date +%T) restarting node $STOPPED_NODE"
    docker start "$STOPPED_NODE" >/dev/null
  fi
  probe_exec "$CLIENT '$([[ "$ENGINE" == "pg" ]] && echo "drop table if exists failover_probe" || echo "drop database if exists probe")'" >/dev/null 2>&1
  k -n "$NS" delete pod "$PROBE" --wait=false >/dev/null 2>&1
}
trap cleanup EXIT

k -n "$NS" delete pod "$PROBE" --ignore-not-found --wait=true >/dev/null
start_probe "$AVOID_ZONE"
if [[ "$ENGINE" == "mysql" ]]; then
  OLD_POD="$(writer)"
  if [[ "$(zone_of_pod "$OLD_POD")" == "$(zone_of_pod "$PROBE")" ]]; then
    # the probe landed in the zone about to fail: move it
    k -n "$NS" delete pod "$PROBE" --wait=true >/dev/null
    start_probe "$(zone_of_pod "$OLD_POD")"
  fi
fi
OLD_ZONE="$(zone_of_pod "$OLD_POD")"
OLD_NODE="$(node_of_pod "$OLD_POD")"
probe_exec "$CLIENT \"$SETUP\"" >/dev/null || {
  echo "Probe could not write before the test; is the cluster healthy?" >&2
  exit 1
}
echo "== $CR: writer is $OLD_POD ($OLD_ZONE, node $OLD_NODE); probe in $(zone_of_pod "$PROBE")"

# The write loop runs inside the probe, one write a second, one line each.
k -n "$NS" exec "$PROBE" -- sh -c "while :; do if $CLIENT \"$WRITE\" >/dev/null 2>&1; then echo \"\$(date +%s) ok\"; else echo \"\$(date +%s) fail\"; fi; sleep 1; done" >"${TMPDIR:-/tmp}/$PROBE.$$" 2>&1 &
LOOP=$!
sleep 5 # a few good writes first

START=$(date +%s)
if [[ "$MODE" == "pod" ]]; then
  k -n "$NS" delete pod "$OLD_POD" --wait=false >/dev/null
  echo "$(date +%T) deleted pod $OLD_POD"
else
  docker stop "$OLD_NODE" >/dev/null
  STOPPED_NODE="$OLD_NODE"
  echo "$(date +%T) stopped node $OLD_NODE: zone $OLD_ZONE is down"
fi

NEW_POD="" NEW_AT="" RECOVERED=""
for _ in $(seq 1 150); do
  sleep 2
  if [[ -z "$NEW_POD" ]]; then
    w="$(writer 2>/dev/null)"
    if [[ -n "$w" && "$w" != "$OLD_POD" ]]; then
      NEW_POD="$w" NEW_AT=$(($(date +%s) - START))
      echo "$(date +%T) new writer after ${NEW_AT} s: $NEW_POD ($(zone_of_pod "$NEW_POD"))"
    fi
  fi
  # Done once writes have recovered: the writer changed or a write failed
  # (the same writer back), and the last 15 writes succeeded.
  [[ -n "$NEW_POD" ]] || grep -q ' fail$' "${TMPDIR:-/tmp}/$PROBE.$$" || continue
  [[ "$(tail -15 "${TMPDIR:-/tmp}/$PROBE.$$" | grep -c ' ok$')" -eq 15 ]] && RECOVERED=1 && break
done
kill "$LOOP" 2>/dev/null
wait "$LOOP" 2>/dev/null

LOG="${TMPDIR:-/tmp}/$PROBE.$$"
OK=$(grep -c ' ok$' "$LOG")
FAILED=$(grep -c ' fail$' "$LOG")
FIRST=$(awk '$2 == "fail" {print $1; exit}' "$LOG")
LAST=$(awk '$2 == "fail" {t = $1} END {print t}' "$LOG")
rm -f "$LOG"

echo
echo "== Result for $CR ($MODE failure)"
echo "  writer:        $OLD_POD ($OLD_ZONE) -> ${NEW_POD:-the same, back after a restart}${NEW_POD:+ ($(zone_of_pod "$NEW_POD"))}"
echo "  writes:        $OK succeeded, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  echo "  write outage:  from $((FIRST - START)) s to $((LAST - START)) s after the failure (~$((LAST - FIRST + 1)) s)"
fi
if [[ -n "$RECOVERED" ]]; then
  probe_exec "$CLIENT \"$([[ "$ENGINE" == "pg" ]] && echo "select count(*) from failover_probe" || echo "select count(*) from probe.failover_probe")\"" |
    sed 's/^/  rows written:  /'
fi

if [[ "$MODE" == "zone" ]]; then
  docker start "$STOPPED_NODE" >/dev/null && STOPPED_NODE=""
  HEAL_START=$(date +%s)
  echo "$(date +%T) node $OLD_NODE restarted; waiting for the cluster to heal"
  # The operator's status can still read healthy from before the zone went
  # down (2026-10-29: "healed 5 s" while pxc-0 rejoined for 50 s). Every
  # member pod must be ready too: Kubernetes marked them not ready when
  # their node was lost, so ready now means since the node came back.
  healed() {
    healthy && [[ "$(k -n "$NS" get pods -l "$MEMBERS" -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' | grep -c True)" -eq 3 ]]
  }
  for _ in $(seq 1 120); do
    sleep 5
    healed && break
  done
  if healed; then
    echo "  healed:        $(($(date +%s) - HEAL_START)) s after the zone came back"
  else
    echo "  NOT healed after 10 minutes: see kube_use.sh" >&2
    HEAL_FAILED=1
  fi
fi
echo "RESULT start=$START first_fail=${FIRST:--} last_fail=${LAST:--} writer=$OLD_POD->${NEW_POD:-same}"
[[ -n "$RECOVERED" ]] || {
  echo "Writes did not recover within 5 minutes." >&2
  exit 1
}
[[ -z "${HEAL_FAILED:-}" ]] || exit 1
