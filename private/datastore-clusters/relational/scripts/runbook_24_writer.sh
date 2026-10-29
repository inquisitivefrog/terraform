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
#      lost (RPO 0), and no write or read failed from 30 s after the probe's
#      writes recovered until the load ended (the app's clients followed the
#      writer)
#   5. verify: relational check_resources.sh passes
# The search SLO is not judged: it fails by design while the planted
# missing index is in place (runbook 17).
# Usage: private/datastore-clusters/relational/scripts/runbook_24_writer.sh pg|mysql [rate] [duration] [dev]
# Changes the cluster: another node usually becomes the writer.
# Log: relational/logs/runbook-24-<engine>-<time>.txt (-FAILED.txt if it fails)

ENGINE="${1:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ ]] || {
  echo "Usage: $0 pg|mysql [rate] [duration] [dev]" >&2
  exit 1
}
RATE="${2:-20}"
DURATION="${3:-5m}"
ENV="${4:-dev}"
RTO=60    # seconds of write outage allowed (RUNBOOKS.md: node or zone failure)
SETTLE=30 # seconds after the probe recovered before k6 requests must all succeed
source "$(dirname "$0")/runbook_lib.sh"
runbook_start 24 "$@"

# --- 0. the cluster is whole before anything changes ---
step "0. Preconditions"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
[[ -n "$(k -n "$NS" get pods -l "app.kubernetes.io/instance=orders-$ENGINE" -o name)" ]] || die "no orders-$ENGINE pods: apply the app root first"
RESTARTS0="$(app_restarts)"
if [[ "$ENGINE" == pg ]]; then
  echo "  primary $(pg_primary), 2 replicas streaming;" \
    "failoverDelay $(k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.spec.failoverDelay}') s"
else
  echo "  PXC ready, Galera 3 members Synced; writer $(my_writer)"
fi
echo "  orders-$ENGINE app restarts so far: $RESTARTS0"

# --- 1. load ---
load_start "$RATE" "$DURATION"

# --- 2. the failure ---
step "2. Kill the writer's pod (failover_test.sh $ENGINE pod)"
FT_OUT="$(mktemp)"
"$LIB_DIR/failover_test.sh" "$ENGINE" pod "$ENV" 2>&1 | tee "$FT_OUT" | sed 's/^/  | /'
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
wait_whole 600 || die "the $ENGINE cluster is not whole 10 minutes after the failure"
if [[ "$ENGINE" == pg ]]; then
  k -n "$NS" get pods -l cnpg.io/cluster=pg -o jsonpath='{range .items[*]}  {.metadata.name}: {.metadata.labels.cnpg\.io/instanceRole}{"\n"}{end}'
fi

# --- 4. what the app saw ---
load_finish "writes fail during the outage, and search fails by design (runbook 17).
  This step judges lost writes and whether requests kept failing after the writer was back."
# The probe opens a new connection for every write, as a restarted or
# scaled-out client would; the app's pooled connections can outlast it
[[ "$OUTAGE" -le "$RTO" ]] || die "the write outage for new connections (~$OUTAGE s) exceeded the RTO ($RTO s)"
judge_writes $((RECOVERED_AT + SETTLE))
echo "  orders-$ENGINE app restarts: $RESTARTS0 -> $(app_restarts)"

# --- 5. verify ---
verify_check
step "Runbook 24 ($ENGINE): passed"
