#!/usr/bin/env bash
# Runbook 16, tune configuration: change one setting through Terraform, let
# the operator roll it out under load, and measure the effect: the same
# fixed-rate load three times before and three times after.
#   before  0. the cluster is whole; the setting's value on every member
#           1. three loads (default 20 requests/s for 5m each), measured;
#              saved to relational/logs/runbook-16-<engine>-before.tsv
#   after   0. the before file; the setting still has its before value
#           1. start a k6 run (pg 15m; mysql 25m: three restarts, the
#              rejoins and two resizes); ask for the clusters apply; watch
#              the rollout: each member back with the new value, how long
#              it was down (summed if it restarts twice), the writer's moves
#                pg     shared_buffers needs a restart: CloudNativePG restarts
#                       the replicas, then switches over (primaryUpdateMethod
#                       switchover) and restarts the old primary
#                mysql  any change to the configuration restarts every node
#                       (SmartUpdate, the writer last); each rejoins by IST
#                       (the write-sets it missed, from a donor's gcache) or,
#                       if the gcache no longer holds them, by SST (a full
#                       copy). IST is expected; an SST fails the run
#           2. mysql only: innodb_buffer_pool_size resized online on a node
#              that is not the writer (SET GLOBAL, 768M -> 512M -> back),
#              timed, under the same load. What Terraform can't do: a change
#              to the configuration restarts every node, even for a setting
#              the server can change live
#           3. what the app saw: errors last at most 30 s; 0 acknowledged
#              writes lost; nothing failed from 30 s after the rollout
#           4. three loads, measured as before; before and after side by side
#           5. verify: relational check_resources.sh passes
#   Measured per load: search p95 (the slower of the two search shapes),
#   create p95, failed requests; pg: blocks read from outside
#   shared_buffers (pg_stat_database blks_read, every instance), per search,
#   and the hit ratio; mysql: the write-set rate (wsrep_replicated_bytes)
#   and how long a node may be down and still rejoin by IST (gcache.size /
#   that rate), and InnoDB reads from disk.
# The effect is reported, not judged: a change that does nothing measurable
# is a result too. The search SLO fails by design (the planted missing
# index, runbook 17).
# Usage: private/datastore-clusters/relational/scripts/runbook_16_tune.sh pg|mysql before|after [rate] [duration] [dev]
# Changes the cluster (after): every member restarts; the writer moves.
# Log: relational/logs/runbook-16-<engine>-<phase>-<time>.txt (-FAILED.txt if it fails)

ENGINE="${1:-}"
PHASE="${2:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ && "$PHASE" =~ ^(before|after)$ ]] || {
  echo "Usage: $0 pg|mysql before|after [rate] [duration] [dev]" >&2
  exit 1
}
RATE="${3:-20}"
DURATION="${4:-5m}"
ENV="${5:-dev}"
RUNS=3
BUDGET=30 # seconds of app errors allowed: a switchover, not an outage (RUNBOOKS.md 13)
SETTLE=30 # seconds after the rollout before every request must succeed
source "$(dirname "$0")/runbook_lib.sh"
RUNBOOK_PHASE="$PHASE" # the after run must not delete the before run's log
runbook_start 16 "$@"
BEFORE_FILE="$LIB_DIR/../logs/runbook-16-$ENGINE-before.tsv"
CLUSTERS_ROOT="$(cd "$LIB_DIR/../environments/$ENV/clusters" && pwd)"

if [[ "$ENGINE" == pg ]]; then
  SETTING=shared_buffers MEMBERS="pg-1 pg-2 pg-3" CONTAINER=postgres
else
  SETTING=gcache.size MEMBERS="mysql-pxc-0 mysql-pxc-1 mysql-pxc-2" CONTAINER=pxc
fi
# value <member>: the setting as the server reports it ("128MB", "128M")
value() {
  if [[ "$ENGINE" == pg ]]; then
    k -n "$NS" exec "$1" -c postgres -- psql -XAtq -c "SHOW shared_buffers" 2>/dev/null
  else
    my_sql "$1" "SELECT @@wsrep_provider_options" 2>/dev/null | tr ';' '\n' | sed -n 's/^ *gcache.size = *//p'
  fi
}
ready() { [[ "$(k -n "$NS" get pod "$1" -o jsonpath="{.status.containerStatuses[?(@.name==\"$CONTAINER\")].ready}" 2>/dev/null)" == true ]]; }
mem_limit() { k -n "$NS" get pod "$1" -o jsonpath="{.spec.containers[?(@.name==\"$CONTAINER\")].resources.limits.memory}"; }
writer() { if [[ "$ENGINE" == pg ]]; then pg_primary; else my_writer; fi; }
bytes() { awk -v v="$1" 'BEGIN { n = v + 0; u = toupper(v); sub(/^[0-9.]+/, "", u)
  print n * (u ~ /^G/ ? 1073741824 : u ~ /^M/ ? 1048576 : u ~ /^K/ ? 1024 : 1) }'; }
# prom_float <query>: one decimal value (prom_value keeps whole numbers only)
prom_float() {
  k get --raw "/api/v1/namespaces/monitoring/services/kube-prometheus-stack-prometheus:http-web/proxy/api/v1/query?query=$(printf %s "$1" | jq -sRr @uri)" 2>/dev/null |
    jq -r '.data.result[0].value[1] // empty'
}
# counters: "<a> <b>" summed over every member
counters() {
  local m
  for m in $MEMBERS; do
    if [[ "$ENGINE" == pg ]]; then
      pg_sql "$m" "SELECT blks_read, blks_hit FROM pg_stat_database WHERE datname = 'appdb'"
    else
      my_sql "$m" "SELECT GROUP_CONCAT(VARIABLE_VALUE ORDER BY VARIABLE_NAME DESC SEPARATOR ' ') FROM performance_schema.global_status
        WHERE VARIABLE_NAME IN ('Innodb_buffer_pool_reads', 'Innodb_buffer_pool_read_requests')"
    fi
  done | awk '{a += $1; b += $2} END {print a + 0, b + 0}'
}

# measure <n>: one load, one tab-separated row appended to $ROWS
#   pg     run testid search_p95_ms create_p95_ms failed lost blks_read reads_per_search hit_pct
#   mysql  run testid search_p95_ms create_p95_ms failed lost writeset_kib_s ist_window_h disk_reads
measure() {
  local c0 c1 search create failed lost searches a b rate size
  c0="$(counters)"
  load_start "$RATE" "$DURATION"
  load_finish "search fails by design (runbook 17); this step only measures"
  c1="$(counters)"
  search="$(prom_float "max(last_over_time(k6_http_req_duration_p95{testid=\"$TESTID\",op=\"search\",expected_response=\"true\"}[2h]))")"
  create="$(prom_float "max(last_over_time(k6_http_req_duration_p95{testid=\"$TESTID\",op=\"create\",expected_response=\"true\"}[2h]))")"
  failed="$(k6_count k6_http_reqs_total ',op=~"create|read|update|delete|search",expected_response="false"')"
  lost="$(k6_count k6_orders_lost_total '')"
  searches="$(k6_count k6_http_reqs_total ',op="search",expected_response="true"')"
  [[ -n "$search" && "$searches" -gt 0 ]] || die "no search results for $TESTID in Prometheus"
  read -r a b <<<"$(awk -v x="$c0" -v y="$c1" 'BEGIN { split(x, p, " "); split(y, q, " "); print q[1] - p[1], q[2] - p[2] }')"
  if [[ "$ENGINE" == pg ]]; then
    # a: blocks read from outside shared_buffers (the OS cache or disk); b: found in it
    ROW="$(awk -v a="$a" -v b="$b" -v s="$searches" 'BEGIN { printf "%d\t%.0f\t%.2f", a, a / s, 100 * b / (a + b) }')"
  else
    rate="$(prom_float "sum(rate(mysql_global_status_wsrep_replicated_bytes{namespace=\"$NS\",pod=~\"mysql-pxc-.*\"}[4m] @ $END_EPOCH))")"
    size="$(bytes "$(value mysql-pxc-0)")"
    # b - a: InnoDB pages wanted; a: of those, read from disk
    ROW="$(awk -v r="${rate:-0}" -v g="$size" -v a="$a" 'BEGIN { printf "%.1f\t%.1f\t%d", r / 1024, (r > 0 ? g / r / 3600 : 0), a }')"
  fi
  ROW="$1	$TESTID	$(awk -v s="$search" -v c="${create:-0}" 'BEGIN { printf "%.1f\t%.1f", s * 1000, c * 1000 }')	$failed	$lost	$ROW"
  echo "  $ROW" | tr '\t' ' '
  # A measurement that failed leaves a short row (mysql 2026-11-05: an awk error)
  [[ "$(awk -F'\t' '{print NF}' <<<"$ROW")" == "$(awk -F'\t' '{print NF}' <<<"$HEADER")" ]] || die "load $1: a column is missing"
  printf '%s\n' "$ROW" >>"$ROWS"
}
HEADER_PG="run	testid	search_p95_ms	create_p95_ms	failed	lost	blks_read	reads_per_search	hit_pct"
HEADER_MY="run	testid	search_p95_ms	create_p95_ms	failed	lost	writeset_kib_s	ist_window_h	disk_reads"
HEADER="$HEADER_PG"
[[ "$ENGINE" == mysql ]] && HEADER="$HEADER_MY"

# --- 0. preconditions ---
step "0. Preconditions"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
[[ -n "$(k -n "$NS" get pods -l "$APP_PODS" -o name)" ]] || die "no orders-$ENGINE pods: apply the app root first"
NOW=""
for m in $MEMBERS; do
  v="$(value "$m")"
  echo "  $m: $SETTING $v, memory limit $(mem_limit "$m")"
  [[ -z "$NOW" || "$v" == "$NOW" ]] || die "the members disagree on $SETTING ($NOW, $v): a rollout in progress?"
  NOW="$v"
done
[[ -n "$NOW" ]] || die "could not read $SETTING"

if [[ "$PHASE" == before ]]; then
  ROWS="$(mktemp)"
  step "1. Before: $RUNS loads of $RATE requests/s for $DURATION"
  for n in $(seq 1 "$RUNS"); do measure "$n"; done
  { echo "# $SETTING $NOW, memory limit $(mem_limit "${MEMBERS%% *}"), $RATE requests/s for $DURATION, $(date -u +%FT%TZ)"
    echo "$HEADER"; cat "$ROWS"; } >"$BEFORE_FILE.tmp" && mv "$BEFORE_FILE.tmp" "$BEFORE_FILE"
  rm -f "$ROWS"
  echo "  Saved: $BEFORE_FILE"
  step "Runbook 16 ($ENGINE) before: done. Change $SETTING in Terraform, then run: $0 $ENGINE after"
  exit 0
fi

[[ -f "$BEFORE_FILE" && "$(grep -cv '^#\|^run' "$BEFORE_FILE")" -eq "$RUNS" ]] || die "no complete $BEFORE_FILE: run '$0 $ENGINE before' first"
OLD="$(sed -n "1s/^# $SETTING \([^,]*\),.*/\1/p" "$BEFORE_FILE")"
echo "  before: $(head -1 "$BEFORE_FILE" | sed 's/^# //')"
[[ "$NOW" == "$OLD" ]] || die "$SETTING is already $NOW (before: $OLD): applied without this run watching; rerun before"
ORIGINAL="$(writer)"
[[ -n "$ORIGINAL" ]] || die "could not tell which member is the writer"
RESTARTS0="$(app_restarts)"
echo "  writer $ORIGINAL; orders-$ENGINE app restarts so far: $RESTARTS0"

# --- 1. the rollout, under load ---
ROLLOUT_LOAD=15m
[[ "$ENGINE" == mysql ]] && ROLLOUT_LOAD=25m
load_start "$RATE" "$ROLLOUT_LOAD"
step "1. Apply the change now, in a second terminal:"
echo "    cd $CLUSTERS_ROOT"
echo "    terraform plan -out plan-clusters   # expect 1 to change: the $ENGINE cluster"
echo "    terraform apply plan-clusters"
echo "  Waiting up to 10 minutes for the first member to restart"
declare -A DOWN=() DONE=() TOOK=() POD=()
pod_uid() { k -n "$NS" get pod "$1" -o jsonpath='{.metadata.uid}' 2>/dev/null; }
QUIET=30 # seconds every member must stay back before the rollout counts as over
t0=$SECONDS
until ((${#DOWN[@]} > 0)); do
  for m in $MEMBERS; do ready "$m" && [[ "$(value "$m")" == "$OLD" ]] || DOWN[$m]=$(date +%s); done
  ((SECONDS - t0 >= 600)) && die "no member restarted within 10 minutes: was the clusters root applied?"
  sleep 2
done
T_START=$(date +%s)
echo "  $(date -u +%H:%M:%S) the rollout started"
LAST_WRITER="$ORIGINAL"
NEW=""
t0=$SECONDS
LAST_BACK=$T_START
while :; do
  for m in $MEMBERS; do
    # down: not ready, or not answering a query (a restart in place may never
    # turn the pod unready between two polls)
    v=""
    ready "$m" && v="$(value "$m")"
    if [[ -n "${DONE[$m]:-}" ]]; then
      # Back, but it may go down again: pg restarts in place for a parameter,
      # then replaces the pod for new resources (pg-1, 2026-11-05)
      if [[ -z "$v" || "$(pod_uid "$m")" != "${POD[$m]}" ]]; then
        echo "  $(date -u +%H:%M:%S) $m down again"
        unset "DONE[$m]"
        DOWN[$m]=$(date +%s)
      fi
      continue
    fi
    if [[ -n "$v" && "$v" != "$OLD" ]]; then
      DONE[$m]=$(date +%s)
      LAST_BACK=${DONE[$m]}
      POD[$m]="$(pod_uid "$m")"
      TOOK[$m]=$((${TOOK[$m]:-0} + DONE[$m] - ${DOWN[$m]:-${DONE[$m]}})) # summed over its restarts
      echo "  $(date -u +%H:%M:%S) $m back with $SETTING $v, memory limit $(mem_limit "$m") (down ~${TOOK[$m]} s in all)"
      [[ -z "$NEW" || "$v" == "$NEW" ]] || die "$m has $v, another member $NEW"
      NEW="$v"
    elif [[ -z "$v" && -z "${DOWN[$m]:-}" ]]; then
      DOWN[$m]=$(date +%s)
    fi
  done
  w="$(writer 2>/dev/null)"
  if [[ -n "$w" && "$w" != "$LAST_WRITER" ]]; then
    echo "  $(date -u +%H:%M:%S) writer $LAST_WRITER -> $w"
    LAST_WRITER="$w"
  fi
  ((${#DONE[@]} == 3 && $(date +%s) - LAST_BACK >= QUIET)) && break
  ((SECONDS - t0 >= 900)) && die "only ${#DONE[@]} of 3 members have the new $SETTING 15 minutes after the rollout started"
  sleep 2
done
wait_whole 300 || die "the cluster is not whole 5 minutes after the last member came back"
# The rollout ended when the last member came back (not after the quiet wait)
T_DONE=$LAST_BACK
LONGEST="$(for m in $MEMBERS; do echo "${TOOK[$m]}"; done | sort -n | tail -1)"
echo "  Rollout: $((T_DONE - T_START)) s from the first restart to the last member back; $SETTING $OLD -> $NEW; writer $ORIGINAL -> $(writer); longest member down ~$LONGEST s"

if [[ "$ENGINE" == mysql ]]; then
  step "1b. How each node rejoined (its log since the restart)"
  for m in $MEMBERS; do
    log="$(k -n "$NS" logs "$m" -c pxc 2>/dev/null)"
    if grep -q 'Proceeding with SST' <<<"$log"; then how=SST
    elif grep -q 'IST received' <<<"$log"; then how="IST ($(grep -m1 -o 'IST received: [^ ]*' <<<"$log" | sed 's/.*://'))"
    else how="no state transfer (nothing missed)"; fi
    echo "  $m: $how"
    [[ "$how" != SST ]] || die "$m rejoined by SST, a full copy: its missed write-sets were no longer in the donor's gcache"
  done

  # --- 2. the online resize ---
  while (($(date +%s) < T_DONE + SETTLE)); do sleep 2; done
  NODE="$(my_nonwriter)" || die "could not find a node that is not the writer"
  POOL="$(my_sql "$NODE" "SELECT @@innodb_buffer_pool_size")"
  step "2. innodb_buffer_pool_size resized online on $NODE (not the writer), under the load"
  resize() {
    local prev start=$SECONDS st
    prev="$(my_sql "$NODE" "SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_resize_status'" | cut -f2)"
    my_sql "$NODE" "SET GLOBAL innodb_buffer_pool_size = $1" || die "SET GLOBAL innodb_buffer_pool_size = $1 failed"
    while :; do
      st="$(my_sql "$NODE" "SELECT GROUP_CONCAT(VARIABLE_VALUE ORDER BY VARIABLE_NAME SEPARATOR '|') FROM performance_schema.global_status
        WHERE VARIABLE_NAME IN ('Innodb_buffer_pool_resize_status', 'Innodb_buffer_pool_resize_status_code')")"
      [[ "${st#*|}" == 0 && "${st%%|*}" == Completed* && "${st%%|*}" != "$prev" ]] && break
      ((SECONDS - start >= 300)) && die "the resize to $1 did not finish in 5 minutes: ${st%%|*}"
      sleep 1
    done
    echo "  $(date -u +%H:%M:%S) $(awk -v b="$1" 'BEGIN { printf "%dM", b / 1048576 }') in $((SECONDS - start)) s: ${st%%|*}"
  }
  resize $((512 * 1048576))
  resize "$POOL"
  echo "  The configuration still says $(k -n "$NS" exec "$NODE" -c pxc -- sh -c 'my_print_defaults mysqld' | sed -n 's/^--innodb_buffer_pool_size=//p'):"
  echo "  a SET GLOBAL lasts until the node restarts; the same change through Terraform restarts every node"
fi

# --- 3. what the app saw ---
load_finish "search fails by design (runbook 17).
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

# --- 4. after ---
ROWS="$(mktemp)"
step "4. After: $RUNS loads of $RATE requests/s for $DURATION"
for n in $(seq 1 "$RUNS"); do measure "$n"; done
step "4b. Before and after ($SETTING $OLD -> $NEW), the median of $RUNS loads each"
grep -v '^#\|^run' "$BEFORE_FILE" >"$ROWS.before"
awk -F'\t' -v header="$HEADER" '
  function median(x, n,   i, j, t) {
    for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++) if (x[j] < x[i]) { t = x[i]; x[i] = x[j]; x[j] = t }
    return n % 2 ? x[(n + 1) / 2] : (x[n / 2] + x[n / 2 + 1]) / 2 }
  FNR == NR { nb++; for (c = 3; c <= NF; c++) b[c, nb] = $c; next }
  { na++; for (c = 3; c <= NF; c++) a[c, na] = $c; cols = NF }
  END {
    split(header, h, "\t")
    printf "  %-18s %12s %12s %8s\n", "", "before", "after", "change"
    for (c = 3; c <= cols; c++) {
      delete x; for (i = 1; i <= nb; i++) x[i] = b[c, i]; mb = median(x, nb)
      delete x; for (i = 1; i <= na; i++) x[i] = a[c, i]; ma = median(x, na)
      ch = mb != 0 ? sprintf("%+.0f%%", 100 * (ma - mb) / mb) : "-"
      printf "  %-18s %12s %12s %8s\n", h[c], mb, ma, ch } }' "$ROWS.before" "$ROWS"
rm -f "$ROWS" "$ROWS.before"

# --- 5. verify ---
verify_check
step "Runbook 16 ($ENGINE): passed, $SETTING $OLD -> $NEW"
