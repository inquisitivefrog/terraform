#!/usr/bin/env bash
# Runbook 24, writer failure: kill the writer's pod under load and prove the
# cluster recovers by itself within the RTO, with no acknowledged write lost.
# Repeatable: the cluster heals itself; the writer stays wherever the
# election put it.
#   0. preconditions: the cluster is whole
#   1. start a k6 run at a quiet rate (default 20 requests/s for 5m); 60 s
#      to settle
#   2. kill the writer (failover_test.sh <engine> pod): its probe writes
#      once a second through the writer endpoint, each on a new connection,
#      and times the outage
#        pg     CloudNativePG waits failoverDelay (5 s), then promotes the
#               replica holding every acknowledged commit, unless the
#               restarted primary is back first and keeps its role
#        mysql  no election: HAProxy sends writes to the next healthy node
#   3. the old writer is back as a member: pg 2 replicas streaming; Galera 3
#      members Synced and the operator ready
#   4. what the app saw (k6's results in Prometheus): no acknowledged write
#      lost (RPO 0), and no write failed from 30 s after the probe's writes
#      recovered until the load ended (the app's clients followed the writer)
#   5. verify: relational check_resources.sh passes
# The search SLO is not judged: it fails by design while the planted
# missing index is in place (runbook 17).
# Usage: private/datastore-clusters/relational/scripts/runbook_24_writer.sh pg|mysql [rate] [duration] [dev]
# Changes the cluster: another node usually becomes the writer.
# Log: relational/logs/runbook-24-<engine>-<time>.txt (-FAILED.txt if it fails)

set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/../../../scripts/private_env.sh" # use_cluster, k, runbook_log
source "$DIR/../../../scripts/checks.sh"      # prom_value

ENGINE="${1:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ ]] || {
  echo "Usage: $0 pg|mysql [rate] [duration] [dev]" >&2
  exit 1
}
RATE="${2:-20}"
DURATION="${3:-5m}"
ENV="${4:-dev}"
NS="relational"
RTO=60   # seconds of write outage allowed (RUNBOOKS.md: node or zone failure)
SETTLE=30 # seconds after the probe recovered before k6 writes must all succeed

use_cluster "datastore-$ENV"
runbook_log "$DIR/../logs" "runbook-24-$ENGINE" "$@"

step() { echo; echo "== $(date -u +%H:%M:%S) $*"; }
die() { echo "FAILED: $*"; exit 1; }
secret() { k -n "$NS" get secret "$1" -o jsonpath="{.data.$2}" | base64 -d; }

pg_whole() {
  local primary
  [[ "$(k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.status.phase}')" == "Cluster in healthy state" ]] || return 1
  primary="$(k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.status.currentPrimary}')"
  [[ "$(k -n "$NS" exec "$primary" -c postgres -- psql -XAtq -c "SELECT count(*) FROM pg_stat_replication WHERE state = 'streaming'" 2>/dev/null)" == 2 ]]
}
my_whole() {
  local pod
  [[ "$(k -n "$NS" get perconaxtradbclusters.pxc.percona.com mysql -o jsonpath='{.status.state} {.status.pxc.ready}')" == "ready 3" ]] || return 1
  for pod in mysql-pxc-0 mysql-pxc-1 mysql-pxc-2; do
    [[ "$(k -n "$NS" exec -i "$pod" -c pxc -- sh -c 'read -r MYSQL_PWD; export MYSQL_PWD; exec mysql -uroot -NBe "$0"' \
      "SELECT GROUP_CONCAT(VARIABLE_VALUE ORDER BY VARIABLE_NAME SEPARATOR ' ') FROM performance_schema.global_status
       WHERE VARIABLE_NAME IN ('wsrep_cluster_size', 'wsrep_local_state_comment')" <<<"$MY_ROOT_PW" 2>/dev/null)" == "3 Synced" ]] || return 1
  done
}
whole() { if [[ "$ENGINE" == pg ]]; then pg_whole; else my_whole; fi; }
app_restarts() { k -n "$NS" get pods -l "app.kubernetes.io/instance=orders-$ENGINE" -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | awk '{n += $1} END {print n + 0}'; }

# --- 0. the cluster is whole before anything changes ---
step "0. Preconditions"
[[ "$ENGINE" == mysql ]] && MY_ROOT_PW="$(secret mysql-secrets root)"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
RESTARTS0="$(app_restarts)"
[[ -n "$(k -n "$NS" get pods -l "app.kubernetes.io/instance=orders-$ENGINE" -o name)" ]] || die "no orders-$ENGINE pods: apply the app root first"
if [[ "$ENGINE" == pg ]]; then
  echo "  primary $(k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.status.currentPrimary}'), 2 replicas streaming;" \
    "failoverDelay $(k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.spec.failoverDelay}') s"
else
  echo "  PXC ready, Galera 3 members Synced"
fi
echo "  orders-$ENGINE app restarts so far: $RESTARTS0"

{
  # --- 1. load ---
  step "1. Load during the failure: $RATE requests/s for $DURATION"
  LOAD_OUT="$(mktemp)"
  "$DIR/load_test.sh" "$ENGINE" run "$RATE" "$DURATION" "$ENV" >"$LOAD_OUT" 2>&1 &
  LOAD_PID=$!
  for _ in $(seq 1 30); do
    TESTID="$(grep -m1 -oE '^Job k6-[a-z]+-run-[0-9-]+' "$LOAD_OUT" | sed 's/^Job k6-//')"
    [[ -n "$TESTID" ]] && break
    sleep 1
  done
  [[ -n "$TESTID" ]] || die "the load did not start: $(cat "$LOAD_OUT")"
  echo "  k6 run $TESTID; 60 s to settle"
  sleep 60

  # --- 2. the failure ---
  step "2. Kill the writer's pod (failover_test.sh $ENGINE pod)"
  FT_OUT="$(mktemp)"
  "$DIR/failover_test.sh" "$ENGINE" pod "$ENV" 2>&1 | tee "$FT_OUT" | sed 's/^/  | /'
  FT_RC="${PIPESTATUS[0]}"
  RESULT="$(grep '^RESULT ' "$FT_OUT")"
  rm -f "$FT_OUT"
  [[ "$FT_RC" -eq 0 && -n "$RESULT" ]] || die "writes did not recover (failover_test.sh exit $FT_RC)"
  field() { sed -E "s/.* $1=([^ ]*).*/\1/" <<<"$RESULT"; }
  START="$(field start)" FIRST="$(field first_fail)" LAST="$(field last_fail)"
  if [[ "$FIRST" == - ]]; then
    OUTAGE=0 RECOVERED_AT="$START"
  else
    OUTAGE=$((LAST - FIRST + 1)) RECOVERED_AT=$((LAST + 1))
  fi
  echo "  Probe: writer $(field writer); write outage ~$OUTAGE s (RTO $RTO s)"

  # --- 3. healed ---
  step "3. The old writer is back as a member"
  HEAL0=$SECONDS
  until whole; do
    ((SECONDS - HEAL0 >= 600)) && die "the $ENGINE cluster is not whole 10 minutes after the failure"
    sleep 5
  done
  echo "  Whole $((SECONDS - HEAL0)) s after the probe finished"
  if [[ "$ENGINE" == pg ]]; then
    k -n "$NS" get pods -l cnpg.io/cluster=pg -o jsonpath='{range .items[*]}  {.metadata.name}: {.metadata.labels.cnpg\.io/instanceRole}{"\n"}{end}'
  fi

  # --- 4. what the app saw ---
  step "4. Waiting for the load to finish"
  wait "$LOAD_PID"
  sleep 10 # k6 pushes to Prometheus every 5 s
  echo "  The background load's own output follows. Its SLO verdict is not used: writes fail"
  echo "  during the outage, and search fails by design (runbook 17). This step judges lost"
  echo "  writes and whether writes kept failing after the writer was back."
  sed 's/^/  | /' "$LOAD_OUT"
  JOB_END="$(k -n "$NS" get job "k6-$TESTID" -o jsonpath='{.status.completionTime}{.status.conditions[?(@.type=="Failed")].lastTransitionTime}')"
  [[ -n "$JOB_END" ]] && END_EPOCH="$(date -u -j -f %Y-%m-%dT%H:%M:%SZ "$JOB_END" +%s)" || END_EPOCH=0
  CUTOFF=$((RECOVERED_AT + SETTLE))
  # $1 metric, $2 extra labels, $3 evaluation time ("" = now)
  q() { prom_value "sum(max_over_time($1{testid=\"$TESTID\"$2}[2h]${3:+ @ $3}))"; }
  FAILED_SEL=',op=~"create|update|delete",expected_response="false"'
  WRITES_OK="$(q k6_http_reqs_total ',op=~"create|update|delete",expected_response="true"')"
  WRITES_FAILED="$(q k6_http_reqs_total "$FAILED_SEL")"
  FAILED_BY_CUTOFF="$(q k6_http_reqs_total "$FAILED_SEL" "$CUTOFF")"
  LOST="$(q k6_orders_lost_total '')"
  RESTARTS1="$(app_restarts)"
  echo "  During the run: $WRITES_OK writes succeeded, $WRITES_FAILED failed ($((WRITES_FAILED - FAILED_BY_CUTOFF)) after" \
    "$(date -u -r "$CUTOFF" +%H:%M:%S), $SETTLE s after the probe recovered); $LOST acknowledged writes lost"
  echo "  orders-$ENGINE app restarts: $RESTARTS0 -> $RESTARTS1"
  [[ "$WRITES_OK" -gt 0 ]] || die "no successful writes found for $TESTID in Prometheus: the check would prove nothing"
  [[ "$LOST" -eq 0 ]] || die "$LOST acknowledged writes were lost (RPO must be 0)"
  # The probe opens a new connection for every write, as a restarted or
  # scaled-out client would; the app's pooled connections can outlast it
  [[ "$OUTAGE" -le "$RTO" ]] || die "the write outage for new connections (~$OUTAGE s) exceeded the RTO ($RTO s)"
  [[ "$WRITES_FAILED" -eq "$FAILED_BY_CUTOFF" ]] || die "app writes still failed after the writer was back"
  [[ "$END_EPOCH" -gt $((CUTOFF + 60)) ]] ||
    die "the load ended less than 60 s after the cutoff: rerun with a longer duration"
  rm -f "$LOAD_OUT"
}

# --- 5. verify ---
step "5. Verify: relational check_resources.sh"
CHECK_OUT="$("$DIR/check_resources.sh" "$ENV" 2>&1)"
CHECK_RC=$?
tail -3 <<<"$CHECK_OUT" | sed 's/^/  /'
[[ "$CHECK_RC" -eq 0 ]] || die "check_resources.sh failed: $(grep -i fail <<<"$CHECK_OUT" | head -5)"
step "Runbook 24 ($ENGINE): passed"
