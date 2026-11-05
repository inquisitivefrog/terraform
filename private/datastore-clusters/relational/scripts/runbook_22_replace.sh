#!/usr/bin/env bash
# Runbook 22, replace a damaged node: delete a replica's pod and its volume
# under load (a dead disk), let the operator build a fresh member from a
# healthy peer, and prove there is no outage and no data loss.
# Repeatable: the replacement is a full member, under the same name.
#   0. preconditions: the cluster is whole; pick the member (a pg replica,
#      or a Galera node HAProxy is not sending writes to; a damaged writer
#      is runbook 24 first); its data size; disk free for the copy
#   1. start a k6 run at a quiet rate (default 20 requests/s for 10m); 60 s
#      to settle
#   2. fence and destroy: delete the member's volume (it stays until the
#      pod is gone), then the pod
#        pg     the same as `kubectl cnpg destroy`: CloudNativePG 1.30
#               rebuilds the instance under the same name on a new volume
#               (older versions made pg-<next>) and clones it from the
#               primary with pg_basebackup (a join Job, deleted when done)
#        mysql  the StatefulSet recreates the pod with an empty volume; it
#               joins by SST (xtrabackup) from a donor Galera picks
#      Every 5 s until whole: state changes (pods, Galera states). A pod
#      recreated while its old volume was still terminating waits forever,
#      so it is deleted again (counted)
#   3. replaced and caught up: the old volume gone, a new one in use; pg 2
#      replicas streaming; Galera 3 members Synced and the operator ready.
#      Copy time (pg the join pod; mysql from the new pod's start), per GB,
#      and the source (pg the primary; mysql the donor, from its log)
#   4. latency during the rebuild: create and search p95 from the app's own
#      histogram, rebuild window against the minute before it
#   5. what the app saw (k6's results in Prometheus): no write failed at
#      all, none lost; reads may fail while the endpoint drops the member,
#      but none from 30 s after it was back; the writer unchanged
#   6. no data lost: after the load, the new member's fingerprint (rows,
#      max id, checksum per table) equals the writer's
#   7. verify: relational check_resources.sh passes
# The search SLO is not judged: it fails by design while the planted
# missing index is in place (runbook 17).
# Usage: private/datastore-clusters/relational/scripts/runbook_22_replace.sh pg|mysql [rate] [duration] [dev]
# Log: relational/logs/runbook-22-<engine>-<time>.txt (-FAILED.txt if it fails)

ENGINE="${1:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ ]] || {
  echo "Usage: $0 pg|mysql [rate] [duration] [dev]" >&2
  exit 1
}
RATE="${2:-20}"
DURATION="${3:-10m}"
ENV="${4:-dev}"
LIMIT=1800 # seconds for the new member to be built and caught up
SETTLE=30  # seconds after it is back before every request must succeed
source "$(dirname "$0")/runbook_lib.sh"
runbook_start 22 "$@"

# data_mib <pod>: the member's data directory
data_mib() {
  if [[ "$ENGINE" == pg ]]; then
    k -n "$NS" exec "$1" -c postgres -- du -sm /var/lib/postgresql/data/pgdata | awk '{print $1}'
  else
    k -n "$NS" exec "$1" -c pxc -- du -sm /var/lib/mysql | awk '{print $1}'
  fi
}
# my_state <pod>: the node's Galera state, or empty (down, or no SQL yet
# while it receives an SST)
my_state() {
  k -n "$NS" exec -i "$1" -c pxc -- sh -c 'read -r MYSQL_PWD; export MYSQL_PWD; exec timeout 5 mysql -uroot -NBe "SHOW GLOBAL STATUS LIKE '\''wsrep_local_state_comment'\''"' \
    <<<"$MY_ROOT_PW" 2>/dev/null | awk -F'\t' '{print $2}'
}
# p95_ms <uri> <method> <from> <to>: the app's p95 over that window
p95_ms() {
  local v
  v="$(prom_float "histogram_quantile(0.95, sum by (le) (increase(http_server_requests_seconds_bucket{job=\"orders-$ENGINE\",uri=\"$1\",method=\"$2\"}[$(($4 - $3))s] @ $4)))")"
  awk -v v="$v" 'BEGIN { if (v == "" || v == "NaN") print "-"; else printf "%.0f ms", v * 1000 }'
}
prom_float() {
  k get --raw "/api/v1/namespaces/monitoring/services/kube-prometheus-stack-prometheus:http-web/proxy/api/v1/query?query=$(printf %s "$1" | jq -sRr @uri)" 2>/dev/null |
    jq -r '.data.result[0].value[1] // empty'
}
epoch() { date -u -j -f %Y-%m-%dT%H:%M:%SZ "$1" +%s; }

# --- 0. preconditions ---
step "0. Preconditions"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
[[ -n "$(k -n "$NS" get pods -l "$APP_PODS" -o name)" ]] || die "no orders-$ENGINE pods: apply the app root first"
if [[ "$ENGINE" == pg ]]; then
  WRITER="$(pg_primary)"
  read -r -a REPLICAS <<<"$(pg_replicas)"
  VICTIM="${REPLICAS[0]}"
  PVCS="$(k -n "$NS" get pvc -l "cnpg.io/cluster=pg,cnpg.io/instanceName=$VICTIM" -o jsonpath='{.items[*].metadata.name}')"
  INSTANCES0="$(k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.status.instanceNames[*]}')"
else
  WRITER="$(my_writer)"
  [[ -n "$WRITER" ]] || die "could not ask HAProxy which node is the writer"
  VICTIM="$(my_nonwriter)"
  PVCS="datadir-$VICTIM"
fi
[[ -n "$VICTIM" && -n "$PVCS" ]] || die "no member to replace, or no volume for it"
PVC_UIDS0="$(k -n "$NS" get pvc $PVCS -o jsonpath='{.items[*].metadata.uid}')"
SIZE_MIB="$(data_mib "$VICTIM")"
FREE_MIB="$(k -n "$NS" exec "$WRITER" -c "$([[ "$ENGINE" == pg ]] && echo postgres || echo pxc)" -- df -m "$([[ "$ENGINE" == pg ]] && echo /var/lib/postgresql/data || echo /var/lib/mysql)" | awk 'END {print $4}')"
echo "  writer $WRITER; the member to replace: $VICTIM (node $(k -n "$NS" get pod "$VICTIM" -o jsonpath='{.spec.nodeName}'), volume $PVCS)"
echo "  its data: $SIZE_MIB MiB; free on the nodes' disk: $FREE_MIB MiB"
((FREE_MIB > 2 * SIZE_MIB)) || die "less than twice the data size free: no headroom for the copy"
RESTARTS0="$(app_restarts)"
echo "  orders-$ENGINE app restarts so far: $RESTARTS0"

# --- 1. load ---
load_start "$RATE" "$DURATION"

# --- 2. fence and destroy ---
step "2. Destroy $VICTIM: its volume, then its pod"
k -n "$NS" delete pvc $PVCS --wait=false >/dev/null || die "could not delete $PVCS"
k -n "$NS" delete pod "$VICTIM" --wait=false >/dev/null || die "could not delete $VICTIM"
T_KILL=$(date +%s)
echo "  deleted at $(date -u -r "$T_KILL" +%H:%M:%S)"

# --- 3. replaced and caught up ---
step "3. A new member built and caught up"
REDELETED=0
J_POD="" J0="" J1=""
LAST=""
DONOR_SEEN=""
sleep 10 # the cluster status still reads whole for a moment
while :; do
  if [[ "$ENGINE" == pg ]]; then
    NOW="$(k -n "$NS" get pods -l cnpg.io/cluster=pg -o jsonpath='{range .items[*]}{.metadata.name}:{.status.phase}{" "}{end}')"
    # The join pod (pg_basebackup) is deleted once the instance exists:
    # keep its times while it is there
    J="$(k -n "$NS" get pods -l cnpg.io/cluster=pg,cnpg.io/jobRole=join \
      -o jsonpath='{range .items[*]}{.metadata.name} {.status.startTime} {.status.containerStatuses[0].state.terminated.finishedAt}{"\n"}{end}' | tail -1)"
    [[ -n "$J" ]] && read -r J_POD J0 J1_SEEN <<<"$J" && [[ -n "${J1_SEEN:-}" ]] && J1="$J1_SEEN"
  else
    NOW="$(k -n "$NS" get pod "$VICTIM" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    STATES=""
    for pod in mysql-pxc-0 mysql-pxc-1 mysql-pxc-2; do
      s="$(my_state "$pod")"
      STATES+="$pod:${s:-(none)} "
      [[ "$s" == Donor* ]] && DONOR_SEEN="$pod"
    done
    NOW="$VICTIM pod ${NOW:-(none)}; $STATES"
  fi
  [[ "$NOW" != "$LAST" ]] && echo "  $(date -u +%H:%M:%S) $NOW" && LAST="$NOW"
  # A pod recreated with the old, terminating volume would hold it forever
  for p in $(k -n "$NS" get pods -l "$([[ "$ENGINE" == pg ]] && echo cnpg.io/cluster=pg || echo app.kubernetes.io/component=pxc)" \
    -o jsonpath='{range .items[?(@.status.phase=="Pending")]}{.metadata.name}{" "}{end}'); do
    for c in $(k -n "$NS" get pod "$p" -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}'); do
      if [[ -n "$(k -n "$NS" get pvc "$c" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null)" ]]; then
        echo "  $p is pending on the terminating volume $c: deleting the pod again"
        k -n "$NS" delete pod "$p" --wait=false >/dev/null
        REDELETED=$((REDELETED + 1))
      fi
    done
  done
  if whole; then
    # The same name on a new volume (pg 1.30 and mysql), or for pg a new
    # instance name
    NEW=""
    uid="$(k -n "$NS" get pvc "${PVCS%% *}" -o jsonpath='{.metadata.uid}' 2>/dev/null)"
    [[ -n "$uid" && " $PVC_UIDS0 " != *" $uid "* ]] && NEW="$VICTIM"
    if [[ "$ENGINE" == pg ]]; then
      for i in $(k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.status.instanceNames[*]}'); do
        [[ " $INSTANCES0 " == *" $i "* ]] || NEW="$i"
      done
    fi
    [[ -n "$NEW" ]] && break
  fi
  (($(date +%s) - T_KILL >= LIMIT)) && die "no new member caught up $LIMIT s after the destroy"
  sleep 5
done
T_BACK=$(date +%s)
echo "  Whole with $NEW, $((T_BACK - T_KILL)) s after the destroy; pods deleted again: $REDELETED"

for c in $PVCS; do
  uid="$(k -n "$NS" get pvc "$c" -o jsonpath='{.metadata.uid}' 2>/dev/null)"
  [[ -n "$uid" && " $PVC_UIDS0 " == *" $uid "* ]] && die "the old volume $c is still there"
done
echo "  the old volume is gone: $PVCS$([[ "$NEW" == "$VICTIM" ]] && echo " (a new one under the same name)")"
NEW_SIZE="$(data_mib "$NEW")"
if [[ "$ENGINE" == pg ]]; then
  [[ "$(pg_primary)" == "$WRITER" ]] || die "the primary changed ($WRITER -> $(pg_primary)): replacing a replica must not move it"
  if [[ -n "$J0" && -n "$J1" ]]; then
    COPY_S=$(($(epoch "$J1") - $(epoch "$J0")))
    echo "  copy: join pod $J_POD (pg_basebackup from the primary $WRITER), $COPY_S s"
  else
    COPY_S=$((T_BACK - T_KILL))
    echo "  the join pod was not seen finishing: copy time is the whole rebuild, $COPY_S s"
  fi
  k -n "$NS" exec "$WRITER" -c postgres -- psql -XAtq -c \
    "SELECT '  ' || application_name || ': ' || state || ', ' || sync_state || ', replay lag ' || coalesce(replay_lag::text, '0') FROM pg_stat_replication ORDER BY 1"
else
  [[ "$(my_writer)" == "$WRITER" ]] || die "the writer changed ($WRITER -> $(my_writer)): replacing a non-writer must not move it"
  S0="$(k -n "$NS" get pod "$NEW" -o jsonpath='{.status.containerStatuses[?(@.name=="pxc")].state.running.startedAt}')"
  COPY_S=$((T_BACK - $(epoch "$S0")))
  DONOR="$(k -n "$NS" logs "$NEW" -c pxc 2>/dev/null | grep -m1 -oE 'Selected [0-9.]+ \([^)]+\)' | sed -E 's/.*\((.*)\)/\1/')"
  echo "  copy: SST to $NEW from donor ${DONOR:-${DONOR_SEEN:-unknown}} (polled: ${DONOR_SEEN:-not seen}), $COPY_S s from the pod's start to Synced"
  # Every joiner also prepares an IST receiver, for the write-sets that
  # arrive during the SST: only the SST line says the copy was full
  [[ -n "$(k -n "$NS" logs "$NEW" -c pxc 2>/dev/null | grep -m1 'Processing SST received')" ]] ||
    die "no 'Processing SST received' in $NEW's log: it did not join by a full SST"
  k -n "$NS" logs "$NEW" -c pxc 2>/dev/null | grep -oE 'Avg:\[[^]]+\] Elapsed:[0-9:]+' | tail -1 | sed 's/^/  SST stream: /'
  [[ "${DONOR:-$DONOR_SEEN}" == "$WRITER" ]] && echo "  the donor was the writer: HAProxy may have moved writes while it was Donor/Desynced"
fi
echo "  new member's data: $NEW_SIZE MiB (old $SIZE_MIB MiB); $(awk -v m="$NEW_SIZE" -v s="$COPY_S" 'BEGIN { printf "%.0f s per GiB", s / (m / 1024) }')"

# --- 4. latency during the rebuild ---
step "4. Latency: the minute before the destroy, then the rebuild ($((T_BACK - T_KILL)) s)"
echo "  create p95: $(p95_ms /orders POST $((T_KILL - 60)) "$T_KILL") -> $(p95_ms /orders POST "$T_KILL" "$T_BACK")"
echo "  search p95: $(p95_ms /orders/_search POST $((T_KILL - 60)) "$T_KILL") -> $(p95_ms /orders/_search POST "$T_KILL" "$T_BACK")"
echo "  read p95:   $(p95_ms '/orders/{id}' GET $((T_KILL - 60)) "$T_KILL") -> $(p95_ms '/orders/{id}' GET "$T_KILL" "$T_BACK")"

# --- 5. what the app saw ---
load_finish "search fails by design (runbook 17).
  This step judges failed and lost writes, and reads after the member was back."
judge_writes $((T_BACK + SETTLE))
[[ "$WRITES_FAILED" -eq 0 ]] || die "$WRITES_FAILED writes failed: replacing a replica must not stop writes"
echo "  orders-$ENGINE app restarts: $RESTARTS0 -> $(app_restarts)"

# --- 6. no data lost ---
step "6. The new member $NEW holds the writer's data"
for _ in $(seq 1 12); do
  FP_W="$(fingerprint "$WRITER")"
  FP_N="$(fingerprint "$NEW")"
  [[ -n "$FP_W" && "$FP_W" == "$FP_N" ]] && break
  sleep 5
done
sed 's/^/  /' <<<"$FP_N"
[[ -n "$FP_W" && "$FP_W" == "$FP_N" ]] || die "$NEW differs from the writer $WRITER: $(tr '\n' ' ' <<<"$FP_W")"
echo "  identical to $WRITER"

# --- 7. verify ---
verify_check
step "Runbook 22 ($ENGINE): passed"
