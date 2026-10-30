#!/usr/bin/env bash
# Runbook 23, planned switchover: move the writer on purpose under load,
# prove the clients follow it and nothing is lost, then move it back.
# Repeatable: it ends with the writer where it started.
#   0. preconditions: the cluster is whole; note the writer and pick a target
#   1. start a k6 run at a quiet rate (default 20 requests/s for 6m); 60 s
#      to settle
#   2. switch over
#        pg     CloudNativePG switchover to a replica: what `kubectl cnpg
#               promote` does, a request in the cluster's status. The
#               primary shuts down, the target is promoted once it has
#               replayed everything, and the old primary rejoins as a
#               replica.
#        mysql  pxc_maint_mode=MAINTENANCE on the writer: its health check
#               fails, so HAProxy sends writes to the next node, while the
#               node itself stays in the cluster
#   3. 60 s on the new writer: no write fails from 30 s after the switch
#   4. switch back: pg promotes the old primary; mysql puts the node back
#      in service (pxc_maint_mode=DISABLED) and HAProxy returns to it
#   5. what the app saw (k6's results in Prometheus): no acknowledged write
#      lost, and no write or read failed from 30 s after the switch back;
#      exactly one writer, the original
#   6. verify: relational check_resources.sh passes
# Usage: private/datastore-clusters/relational/scripts/runbook_23_switchover.sh pg|mysql [rate] [duration] [dev]
# Log: relational/logs/runbook-23-<engine>-<time>.txt (-FAILED.txt if it fails)

ENGINE="${1:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ ]] || {
  echo "Usage: $0 pg|mysql [rate] [duration] [dev]" >&2
  exit 1
}
RATE="${2:-20}"
DURATION="${3:-6m}"
ENV="${4:-dev}"
SETTLE=30 # seconds after a switch before every request must succeed
source "$(dirname "$0")/runbook_lib.sh"
runbook_start 23 "$@"

writer() { if [[ "$ENGINE" == pg ]]; then pg_primary; else my_writer; fi; }

# pg_promote <instance>: request a switchover, as the cnpg plugin does
pg_promote() {
  k -n "$NS" patch clusters.postgresql.cnpg.io pg --subresource=status --type=merge -p "{\"status\": {
    \"targetPrimary\": \"$1\", \"targetPrimaryTimestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000000Z)\",
    \"phase\": \"Switchover in progress\", \"phaseReason\": \"Switching over to $1\"}}" >/dev/null
}
# my_maint <pod> MAINTENANCE|DISABLED
my_maint() { my_sql "$1" "SET GLOBAL pxc_maint_mode = '$2'"; }

# switch <expected writer> <command...>: run it, then wait until the writer
# is the expected one and the cluster is whole again
switch() {
  local expect="$1" t0=$SECONDS
  shift
  "$@" || die "the switch command failed"
  until [[ "$(writer 2>/dev/null)" == "$expect" ]]; do
    ((SECONDS - t0 >= 180)) && die "the writer is $(writer 2>/dev/null), not $expect, 180 s after the switch"
    sleep 1
  done
  echo "  writer is $expect after $((SECONDS - t0)) s"
  wait_whole 300 || die "the cluster is not whole 5 minutes after the switch"
}

# A node left in maintenance would silently stay out of HAProxy's rotation
MAINT_NODE=""
restore_maint() {
  [[ -n "$MAINT_NODE" ]] || return 0
  echo "  Putting $MAINT_NODE back in service (pxc_maint_mode=DISABLED)"
  my_maint "$MAINT_NODE" DISABLED && MAINT_NODE=""
}
trap 'rc=$?; (restore_maint); _runbook_log_end "$rc"; exit "$rc"' EXIT

# --- 0. preconditions ---
step "0. Preconditions"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
[[ -n "$(k -n "$NS" get pods -l "$APP_PODS" -o name)" ]] || die "no orders-$ENGINE pods: apply the app root first"
RESTARTS0="$(app_restarts)"
ORIGINAL="$(writer)"
[[ -n "$ORIGINAL" ]] || die "could not tell which node is the writer"
if [[ "$ENGINE" == pg ]]; then
  read -r -a REPLICAS <<<"$(pg_replicas)"
  TARGET="${REPLICAS[0]}"
  echo "  primary $ORIGINAL; switching over to $TARGET and back"
else
  [[ "$(my_sql "$ORIGINAL" "SELECT @@pxc_maint_mode")" == DISABLED ]] || die "$ORIGINAL is already in maintenance mode"
  echo "  writer $ORIGINAL; putting it in maintenance, then back in service"
fi
echo "  orders-$ENGINE app restarts so far: $RESTARTS0"

# --- 1. load ---
load_start "$RATE" "$DURATION"

# --- 2. switch over ---
if [[ "$ENGINE" == pg ]]; then
  step "2. Switch over: $ORIGINAL -> $TARGET"
  T_SWITCH=$(date +%s)
  switch "$TARGET" pg_promote "$TARGET"
else
  step "2. Switch over: $ORIGINAL to maintenance"
  T_SWITCH=$(date +%s)
  MAINT_NODE="$ORIGINAL"
  my_maint "$ORIGINAL" MAINTENANCE || die "could not set pxc_maint_mode on $ORIGINAL"
  t0=$SECONDS
  until [[ -n "$(writer 2>/dev/null)" && "$(writer 2>/dev/null)" != "$ORIGINAL" ]]; do
    ((SECONDS - t0 >= 180)) && die "HAProxy still sends writes to $ORIGINAL 180 s after maintenance mode"
    sleep 1
  done
  TARGET="$(writer)"
  echo "  writer is $TARGET after $((SECONDS - t0)) s"
fi
T_SWITCHED=$(date +%s)

# --- 3. on the new writer ---
step "3. 60 s of load on $TARGET"
sleep 60
T_ON_NEW=$(date +%s)
sleep 10 # k6 pushes every 5 s
F_SETTLED="$(k6_count k6_http_reqs_total "$WRITES,expected_response=\"false\"" $((T_SWITCHED + SETTLE)))"
F_BEFORE_BACK="$(k6_count k6_http_reqs_total "$WRITES,expected_response=\"false\"" "$T_ON_NEW")"
echo "  Writes failed so far: $F_BEFORE_BACK ($((F_BEFORE_BACK - F_SETTLED)) from 30 s after the switch)"
[[ "$F_BEFORE_BACK" -eq "$F_SETTLED" ]] || die "writes still failed on the new writer $TARGET"

# --- 4. switch back ---
T_BACK_START=$(date +%s)
if [[ "$ENGINE" == pg ]]; then
  step "4. Switch back: $TARGET -> $ORIGINAL"
  switch "$ORIGINAL" pg_promote "$ORIGINAL"
else
  step "4. Switch back: $ORIGINAL in service"
  switch "$ORIGINAL" restore_maint
fi
T_BACK=$(date +%s)
echo "  Switch over and back: $((T_SWITCHED - T_SWITCH)) s and $((T_BACK - T_BACK_START)) s to a new writer"

# --- 5. what the app saw ---
load_finish "search fails by design (runbook 17).
  This step judges lost writes and requests failing after each switch."
judge_writes $((T_BACK + SETTLE))
[[ "$(writer)" == "$ORIGINAL" ]] || die "the writer is $(writer), not $ORIGINAL"
if [[ "$ENGINE" == pg ]]; then
  [[ "$(k -n "$NS" get pods -l cnpg.io/cluster=pg,cnpg.io/instanceRole=primary -o name | wc -l | tr -d ' ')" == 1 ]] ||
    die "more than one pod is labelled primary"
fi
echo "  One writer, $ORIGINAL, as before"
echo "  orders-$ENGINE app restarts: $RESTARTS0 -> $(app_restarts)"

# --- 6. verify ---
verify_check
step "Runbook 23 ($ENGINE): passed"
