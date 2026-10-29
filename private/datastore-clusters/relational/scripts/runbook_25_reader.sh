#!/usr/bin/env bash
# Runbook 25, reader failure: kill a replica's pod under load and prove it
# costs read capacity only: no write fails, nothing is lost, and reads are
# back to normal once the replica is.
# Repeatable: the replica comes back by itself.
#   0. preconditions: the cluster is whole; pick the replica
#        pg     a CloudNativePG replica (quorum commit, ANY 1 of 2: the
#               other replica acknowledges commits while it is down)
#        mysql  a Galera node HAProxy is not sending writes to (every node
#               votes; 2 of 3 keep the cluster primary)
#   1. start a k6 run at a quiet rate (default 20 requests/s for 5m); 60 s
#      to settle
#   2. delete the replica's pod
#   3. it is back and caught up: pg 2 replicas streaming; Galera 3 members
#      Synced and the operator ready (prints how long it took)
#   4. what the app saw (k6's results in Prometheus): no write failed at
#      all, none lost; reads may fail while the reader endpoint drops the
#      replica (counted), but none from 30 s after it was back
#   5. verify: relational check_resources.sh passes
# Usage: private/datastore-clusters/relational/scripts/runbook_25_reader.sh pg|mysql [rate] [duration] [dev]
# Log: relational/logs/runbook-25-<engine>-<time>.txt (-FAILED.txt if it fails)

ENGINE="${1:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ ]] || {
  echo "Usage: $0 pg|mysql [rate] [duration] [dev]" >&2
  exit 1
}
RATE="${2:-20}"
DURATION="${3:-5m}"
ENV="${4:-dev}"
SETTLE=30 # seconds after the replica is back before every read must succeed
source "$(dirname "$0")/runbook_lib.sh"
runbook_start 25 "$@"

# --- 0. preconditions ---
step "0. Preconditions"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
[[ -n "$(k -n "$NS" get pods -l "app.kubernetes.io/instance=orders-$ENGINE" -o name)" ]] || die "no orders-$ENGINE pods: apply the app root first"
RESTARTS0="$(app_restarts)"
if [[ "$ENGINE" == pg ]]; then
  WRITER="$(pg_primary)"
  read -r -a REPLICAS <<<"$(pg_replicas)"
  VICTIM="${REPLICAS[0]}"
else
  WRITER="$(my_writer)"
  [[ -n "$WRITER" ]] || die "could not ask HAProxy which node is the writer"
  for pod in mysql-pxc-0 mysql-pxc-1 mysql-pxc-2; do
    [[ "$pod" != "$WRITER" ]] && VICTIM="$pod" && break
  done
fi
echo "  writer $WRITER; the replica to kill: $VICTIM (node $(k -n "$NS" get pod "$VICTIM" -o jsonpath='{.spec.nodeName}'))"
echo "  orders-$ENGINE app restarts so far: $RESTARTS0"

# --- 1. load ---
load_start "$RATE" "$DURATION"

# --- 2. the failure ---
step "2. Delete the replica's pod $VICTIM"
k -n "$NS" delete pod "$VICTIM" --wait=false >/dev/null || die "could not delete $VICTIM"
T_KILL=$(date +%s)

# --- 3. back and caught up ---
step "3. $VICTIM back and caught up"
sleep 10 # the cluster status still reads whole for a moment
wait_whole 600 || die "the $ENGINE cluster is not whole 10 minutes after the failure"
T_BACK=$(date +%s)
echo "  $((T_BACK - T_KILL)) s after the pod was deleted"
if [[ "$ENGINE" == pg ]]; then
  [[ "$(pg_primary)" == "$WRITER" ]] || die "the primary changed ($WRITER -> $(pg_primary)): a replica failure must not move it"
  k -n "$NS" exec "$WRITER" -c postgres -- psql -XAtq -c \
    "SELECT '  ' || application_name || ': ' || state || ', ' || sync_state || ', replay lag ' || coalesce(replay_lag::text, '0') FROM pg_stat_replication ORDER BY 1"
else
  [[ "$(my_writer)" == "$WRITER" ]] || die "the writer changed ($WRITER -> $(my_writer)): a replica failure must not move it"
  echo "  writer still $WRITER"
fi

# --- 4. what the app saw ---
load_finish "search fails by design (runbook 17).
  This step judges failed and lost writes, and reads after the replica was back."
judge_writes $((T_BACK + SETTLE))
[[ "$WRITES_FAILED" -eq 0 ]] || die "$WRITES_FAILED writes failed: losing a replica must not stop writes"
echo "  orders-$ENGINE app restarts: $RESTARTS0 -> $(app_restarts)"

# --- 5. verify ---
verify_check
step "Runbook 25 ($ENGINE): passed"
