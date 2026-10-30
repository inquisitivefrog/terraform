#!/usr/bin/env bash
# Runbook 13, security patch (minor version): move every member to the new
# minor release under load, one at a time, and prove the app saw seconds of
# errors at most and nothing acknowledged was lost.
# The version is pinned in Terraform, so the patch goes through Terraform:
# bump the image in environments/dev/clusters/variables.tf first (the target
# this script expects is read from there), then run this; when it asks, apply
# the clusters root in a second terminal. The script watches and judges.
#   0. preconditions: the cluster is whole; every member runs another image
#      than the target in variables.tf
#   1. start a k6 run (default 20 requests/s for 15m); 60 s to settle
#   2. ask for the apply; wait (up to 10 min) for the first member to change
#   3. watch the rollout (up to 15 min): when each member comes back on the
#      new image, and when the writer moves
#        pg     CloudNativePG updates the replicas one at a time, then
#               switches over to one of them (primaryUpdateMethod
#               switchover) and updates the old primary
#        mysql  PXC SmartUpdate restarts the nodes one at a time, the
#               writer last; HAProxy sends writes to the next node
#   4. every member reports the new version from inside the server
#   5. what the app saw (k6's results in Prometheus): no acknowledged write
#      lost; the app's errors (first to last failed request, searches left
#      out as below) last at most 30 s; nothing failed from 30 s after the
#      last member was back
#   6. verify: relational check_resources.sh passes
# The search SLO is not judged: it fails by design on mysql while the
# planted missing index is in place (runbook 17).
# Repeatable with a new target: PostgreSQL can go back a minor too (same
# on-disk format); MySQL 8.0 cannot go back, so on mysql it only moves forward
# (or rebuild the clusters root).
# Usage: private/datastore-clusters/relational/scripts/runbook_13_patch.sh pg|mysql [rate] [duration] [dev]
# Changes the cluster: every member restarts on the new image; the writer moves.
# Log: relational/logs/runbook-13-<engine>-<time>.txt (-FAILED.txt if it fails)

ENGINE="${1:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ ]] || {
  echo "Usage: $0 pg|mysql [rate] [duration] [dev]" >&2
  exit 1
}
RATE="${2:-20}"
DURATION="${3:-15m}"
ENV="${4:-dev}"
BUDGET=30 # seconds of app errors allowed: a switchover, not an outage (RUNBOOKS.md 13)
SETTLE=30 # seconds after the last member is back before every request must succeed
source "$(dirname "$0")/runbook_lib.sh"
runbook_start 13 "$@"

CLUSTERS_ROOT="$(cd "$LIB_DIR/../environments/$ENV/clusters" && pwd)"
if [[ "$ENGINE" == pg ]]; then
  VAR=postgres_image SEL="cnpg.io/cluster=pg,cnpg.io/podRole=instance" CONTAINER=postgres
else
  VAR=pxc_image SEL="app.kubernetes.io/instance=mysql,app.kubernetes.io/component=pxc" CONTAINER=pxc
fi
TARGET="$(awk -v v="variable \"$VAR\"" '$0 ~ v {f = 1} f && /^ *default *=/ {gsub(/.*= *"|".*/, ""); print; exit}' "$CLUSTERS_ROOT/variables.tf")"
[[ -n "$TARGET" ]] || die "no default for $VAR in $CLUSTERS_ROOT/variables.tf"
# 16.15 from ...postgresql:16.15-standard-trixie, 8.0.46 from ...cluster:8.0.46-38.1
TARGET_VERSION="$(sed -E 's/.*:([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/' <<<"$TARGET")"

writer() { if [[ "$ENGINE" == pg ]]; then pg_primary; else my_writer; fi; }
# images: "<pod> <image> <ready>" per member
images() {
  k -n "$NS" get pods -l "$SEL" -o jsonpath="{range .items[*]}{.metadata.name} {.spec.containers[?(@.name==\"$CONTAINER\")].image} {.status.containerStatuses[?(@.name==\"$CONTAINER\")].ready}{\"\\n\"}{end}"
}
# server_version <pod>: as the server itself reports it
server_version() {
  if [[ "$ENGINE" == pg ]]; then
    k -n "$NS" exec "$1" -c postgres -- psql -XAtq -c "SHOW server_version"
  else
    my_sql "$1" "SELECT @@version"
  fi
}

# --- 0. preconditions ---
step "0. Preconditions"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
[[ -n "$(k -n "$NS" get pods -l "$APP_PODS" -o name)" ]] || die "no orders-$ENGINE pods: apply the app root first"
if [[ "$ENGINE" == pg ]]; then
  METHOD="$(k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.spec.primaryUpdateMethod}')"
  [[ "$METHOD" == switchover ]] || die "primaryUpdateMethod is '$METHOD', not switchover: the primary would restart in place (apply the clusters root first)"
fi
echo "  target (variables.tf $VAR): $TARGET"
while read -r pod image _; do
  echo "  $pod: $image, server $(server_version "$pod")"
  [[ "$image" != "$TARGET" ]] || die "$pod already runs $TARGET: set a new version in variables.tf"
done < <(images)
ORIGINAL="$(writer)"
[[ -n "$ORIGINAL" ]] || die "could not tell which node is the writer"
RESTARTS0="$(app_restarts)"
echo "  writer $ORIGINAL; orders-$ENGINE app restarts so far: $RESTARTS0"

# --- 1. load ---
load_start "$RATE" "$DURATION"

# --- 2. the apply ---
step "2. Apply the patch now, in a second terminal:"
echo "    cd $CLUSTERS_ROOT"
echo "    terraform plan -out plan-clusters   # expect 1 to change: $VAR -> $TARGET"
echo "    terraform apply plan-clusters"
echo "  Waiting up to 10 minutes for the first member to change"
t0=$SECONDS
until images | awk -v t="$TARGET" '$2 == t {f = 1} END {exit !f}'; do
  ((SECONDS - t0 >= 600)) && die "no member changed to $TARGET within 10 minutes: was the clusters root applied?"
  sleep 2
done
T_START=$(date +%s)
echo "  $(date -u +%H:%M:%S) the rollout started"

# --- 3. the rollout ---
step "3. Rollout"
declare -A DONE=()
LAST_WRITER="$ORIGINAL"
t0=$SECONDS
while :; do
  while read -r pod image ready; do
    if [[ "$image" == "$TARGET" && "$ready" == true && -z "${DONE[$pod]:-}" ]]; then
      DONE[$pod]=$((SECONDS - t0))
      echo "  $(date -u +%H:%M:%S) $pod back on the new image (+${DONE[$pod]} s)"
    fi
  done < <(images)
  w="$(writer 2>/dev/null)"
  if [[ -n "$w" && "$w" != "$LAST_WRITER" ]]; then
    echo "  $(date -u +%H:%M:%S) writer $LAST_WRITER -> $w"
    LAST_WRITER="$w"
  fi
  ((${#DONE[@]} == 3)) && break
  ((SECONDS - t0 >= 900)) && die "only ${#DONE[@]} of 3 members on $TARGET 15 minutes after the rollout started"
  sleep 2
done
wait_whole 300 || die "the cluster is not whole 5 minutes after the last member came back"
T_DONE=$(date +%s)
echo "  Rollout: $((T_DONE - T_START)) s from the first change to whole; writer $ORIGINAL -> $(writer)"

# --- 4. versions ---
step "4. Versions, from inside each server"
while read -r pod _; do
  v="$(server_version "$pod")"
  echo "  $pod: $v"
  [[ "$v" == "$TARGET_VERSION"* ]] || die "$pod reports $v, not $TARGET_VERSION"
done < <(images)

# --- 5. what the app saw ---
load_finish "search fails by design on mysql (runbook 17).
  This step judges lost writes, the app's errors and requests failing after the rollout."
WINDOW="$(k6_fail_window ',op=~"create|update|delete|read"')"
if [[ -n "$WINDOW" ]]; then
  read -r UFIRST ULAST <<<"$WINDOW"
  USER_ERRORS=$((ULAST - UFIRST + 5))
  echo "  The app's requests failed from $(date -u -r "$UFIRST" +%H:%M:%S) to $(date -u -r "$ULAST" +%H:%M:%S): ~$USER_ERRORS s"
else
  USER_ERRORS=0
  echo "  No app request failed"
fi
judge_writes $((T_DONE + SETTLE))
echo "  orders-$ENGINE app restarts: $RESTARTS0 -> $(app_restarts)"
[[ "$USER_ERRORS" -le "$BUDGET" ]] || die "the app saw ~$USER_ERRORS s of errors (budget $BUDGET s)"

# --- 6. verify ---
verify_check
step "Runbook 13 ($ENGINE): passed, every member on $TARGET_VERSION"
