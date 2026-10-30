#!/usr/bin/env bash
# Runbook 26, zone outage: stop every node of the writer's zone under load
# (in this lab one zone is one node container) and prove writes resume
# within the RTO, nothing acknowledged is lost, and the zone rejoins when it
# comes back. The worst zone to lose: it holds the writer, and the app pod
# there goes with it.
# Repeatable: the zone comes back and the cluster heals; the writer stays
# wherever the election put it.
#   0. preconditions: the cluster is whole; find the writer's zone
#   1. start a k6 run outside that zone (the users are not in the
#      datacenter; default 20 requests/s for 6m); 60 s to settle
#   2. failover_test.sh <engine> zone: docker stop the zone's node; its
#      probe (in another zone) writes once a second on a new connection and
#      times the outage; then the node starts again and the test waits for
#      every member to be ready
#   3. what the app saw (k6's results in Prometheus): no acknowledged write
#      lost (RPO 0), and no write or read failed from 30 s after the probe's
#      writes recovered until the load ended
#   4. both outages are within the RTO (60 s): the probe's (the database)
#      and the app's (first to last failed request in k6, searches left out
#      as below), which also waits for Kubernetes to drop the dead zone's
#      app pod from the Service
#   5. verify: relational check_resources.sh passes
# The search SLO is not judged: it fails by design on mysql while the
# planted missing index is in place (runbook 17).
# Usage: private/datastore-clusters/relational/scripts/runbook_26_zone.sh pg|mysql [rate] [duration] [dev]
# Changes the cluster: another node usually becomes the writer.
# Log: relational/logs/runbook-26-<engine>-<time>.txt (-FAILED.txt if it fails)

ENGINE="${1:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ ]] || {
  echo "Usage: $0 pg|mysql [rate] [duration] [dev]" >&2
  exit 1
}
RATE="${2:-20}"
DURATION="${3:-6m}"
ENV="${4:-dev}"
RTO=60    # seconds of write outage allowed (RUNBOOKS.md: node or zone failure)
SETTLE=30 # seconds after the probe recovered before k6 requests must all succeed
source "$(dirname "$0")/runbook_lib.sh"
runbook_start 26 "$@"

zone_of() { k get node "$(k -n "$NS" get pod "$1" -o jsonpath='{.spec.nodeName}')" -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'; }

# --- 0. preconditions ---
step "0. Preconditions"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
[[ -n "$(k -n "$NS" get pods -l "app.kubernetes.io/instance=orders-$ENGINE" -o name)" ]] || die "no orders-$ENGINE pods: apply the app root first"
if [[ "$ENGINE" == pg ]]; then WRITER="$(pg_primary)"; else WRITER="$(my_writer)"; fi
[[ -n "$WRITER" ]] || die "could not tell which node is the writer"
ZONE="$(zone_of "$WRITER")"
RESTARTS0="$(app_restarts)"
NODE="$(k -n "$NS" get pod "$WRITER" -o jsonpath='{.spec.nodeName}')"
echo "  writer $WRITER in zone $ZONE (node $NODE)"
echo "  also in $ZONE: $(k -n "$NS" get pods --field-selector "spec.nodeName=$NODE,status.phase=Running" -o name | sed 's|pod/||' | grep -vx "$WRITER" | xargs)"
echo "  orders-$ENGINE app restarts so far: $RESTARTS0"

# --- 1. load, from outside the zone ---
export K6_AVOID_ZONE="$ZONE"
load_start "$RATE" "$DURATION"
echo "  k6 runs in zone $(zone_of "$(k -n "$NS" get pods -l "job-name=k6-$TESTID" -o jsonpath='{.items[0].metadata.name}')")"

# --- 2. the zone goes down, then comes back ---
step "2. Zone $ZONE down (failover_test.sh $ENGINE zone)"
FT_OUT="$(mktemp)"
"$LIB_DIR/failover_test.sh" "$ENGINE" zone "$ENV" 2>&1 | tee "$FT_OUT" | sed 's/^/  | /'
FT_RC="${PIPESTATUS[0]}"
RESULT="$(grep '^RESULT ' "$FT_OUT")"
rm -f "$FT_OUT"
[[ -n "$RESULT" ]] || die "failover_test.sh gave no result (exit $FT_RC)"
[[ "$FT_RC" -eq 0 ]] || die "writes did not recover, or the cluster did not heal after the zone came back (failover_test.sh exit $FT_RC)"
field() { sed -E "s/.* $1=([^ ]*).*/\1/" <<<"$RESULT"; }
START="$(field start)" FIRST="$(field first_fail)" LAST="$(field last_fail)"
if [[ "$FIRST" == - ]]; then
  OUTAGE=0 RECOVERED_AT="$START"
else
  OUTAGE=$((LAST - FIRST + 1)) RECOVERED_AT=$((LAST + 1))
fi
echo "  Probe: writer $(field writer); write outage ~$OUTAGE s (RTO $RTO s)"
wait_whole 300 || die "the $ENGINE cluster is not whole 5 minutes after the zone came back"

# --- 3. what the app saw ---
load_finish "writes fail during the outage, and search fails by design on mysql
  (runbook 17). This step judges lost writes and requests failing after recovery."
WINDOW="$(k6_fail_window ',op=~"create|update|delete|read"')"
if [[ -n "$WINDOW" ]]; then
  read -r UFIRST ULAST <<<"$WINDOW"
  USER_OUTAGE=$((ULAST - UFIRST + 5))
  echo "  The app's requests failed from $(date -u -r "$UFIRST" +%H:%M:%S) to $(date -u -r "$ULAST" +%H:%M:%S): ~$USER_OUTAGE s"
else
  USER_OUTAGE=0
  echo "  No app request failed"
fi
judge_writes $((RECOVERED_AT + SETTLE))
echo "  orders-$ENGINE app restarts: $RESTARTS0 -> $(app_restarts)"

# --- 4. the RTO ---
step "4. Outages against the RTO"
echo "  database ~$OUTAGE s (probe), app ~$USER_OUTAGE s (k6); RTO $RTO s"
[[ "$OUTAGE" -le "$RTO" ]] || die "the write outage (~$OUTAGE s) exceeded the RTO ($RTO s)"
[[ "$USER_OUTAGE" -le "$RTO" ]] || die "the app's outage (~$USER_OUTAGE s) exceeded the RTO ($RTO s)"

# --- 5. verify ---
verify_check
step "Runbook 26 ($ENGINE): passed"
