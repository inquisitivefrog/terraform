# Shared by the relational runbook scripts (runbook_<n>_*.sh); sourced, not
# run. Each script sets ENGINE (pg|mysql) and ENV, then sources this, which
# picks the cluster and opens the script's log.
#   runbook_start <n> "$@"        cluster, log, MY_ROOT_PW for mysql
#   step / die                    "== <time> <title>" / "FAILED: ..." and exit 1
#   whole                         the cluster has all 3 members, replicating
#   wait_whole <seconds>          until whole; prints how long it took
#   pg_primary, pg_replicas       instance names
#   my_sql <pod> <sql>            as root over the node's local socket
#   my_writer                     the node HAProxy sends writes to
#   load_start <rate> <duration>  k6 run in the background; 60 s to settle
#   load_finish <why>             wait for it, print its output; sets END_EPOCH
#   k6_count <metric> <labels> [epoch]   a counter of this run (at a time)
#   k6_fail_window <labels>       "first last" epochs of the run's failed
#                                 requests (5 s resolution); empty if none
#   judge_writes <cutoff>         0 lost; no write failed after <cutoff>
#   APP_PODS                      label selector for the app's pods (not k6's,
#                                 which share the instance label)
#   app_restarts                  restarts of the app's pods, summed
#   verify_check                  relational check_resources.sh passes

set -uo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/../../../scripts/private_env.sh" # use_cluster, k, runbook_log
source "$LIB_DIR/../../../scripts/checks.sh"      # prom_value
NS="relational"

runbook_start() {
  local n="$1"
  shift
  use_cluster "datastore-$ENV"
  APP_PODS="app.kubernetes.io/name=orders,app.kubernetes.io/instance=orders-$ENGINE"
  runbook_log "$LIB_DIR/../logs" "runbook-$n-$ENGINE" "$@"
  [[ "$ENGINE" == mysql ]] && MY_ROOT_PW="$(k -n "$NS" get secret mysql-secrets -o jsonpath='{.data.root}' | base64 -d)"
  return 0
}

step() { echo; echo "== $(date -u +%H:%M:%S) $*"; }
die() { echo "FAILED: $*"; exit 1; }

# --- cluster state ---
pg_primary() { k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.status.currentPrimary}'; }
pg_replicas() { k -n "$NS" get pods -l cnpg.io/cluster=pg,cnpg.io/instanceRole=replica -o jsonpath='{.items[*].metadata.name}'; }
pg_whole() {
  [[ "$(k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.status.phase}')" == "Cluster in healthy state" ]] || return 1
  [[ "$(k -n "$NS" exec "$(pg_primary)" -c postgres -- psql -XAtq -c "SELECT count(*) FROM pg_stat_replication WHERE state = 'streaming'" 2>/dev/null)" == 2 ]]
}
my_sql() {
  k -n "$NS" exec -i "$1" -c pxc -- sh -c 'read -r MYSQL_PWD; export MYSQL_PWD; exec mysql -uroot -NBe "$0"' "$2" <<<"$MY_ROOT_PW"
}
# Asked through the writer endpoint, as any client would, from whichever
# node answers (one may be down)
my_writer() {
  local pod
  for pod in mysql-pxc-0 mysql-pxc-1 mysql-pxc-2; do
    k -n "$NS" exec -i "$pod" -c pxc -- sh -c 'read -r MYSQL_PWD; export MYSQL_PWD; exec timeout 5 mysql -uroot -h mysql-haproxy --connect-timeout=3 -NBe "SELECT @@hostname"' \
      <<<"$MY_ROOT_PW" 2>/dev/null && return 0
  done
  return 1
}
my_whole() {
  local pod
  [[ "$(k -n "$NS" get perconaxtradbclusters.pxc.percona.com mysql -o jsonpath='{.status.state} {.status.pxc.ready}')" == "ready 3" ]] || return 1
  for pod in mysql-pxc-0 mysql-pxc-1 mysql-pxc-2; do
    [[ "$(my_sql "$pod" "SELECT GROUP_CONCAT(VARIABLE_VALUE ORDER BY VARIABLE_NAME SEPARATOR ' ') FROM performance_schema.global_status
       WHERE VARIABLE_NAME IN ('wsrep_cluster_size', 'wsrep_local_state_comment')" 2>/dev/null)" == "3 Synced" ]] || return 1
  done
}
whole() { if [[ "$ENGINE" == pg ]]; then pg_whole; else my_whole; fi; }
wait_whole() {
  local start=$SECONDS
  until whole; do
    ((SECONDS - start >= $1)) && return 1
    sleep 5
  done
  echo "  Whole after $((SECONDS - start)) s"
}
app_restarts() {
  k -n "$NS" get pods -l "$APP_PODS" \
    -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | awk '{n += $1} END {print n + 0}'
}

# --- the k6 load and its results in Prometheus ---
load_start() {
  step "Load: $1 requests/s for $2"
  LOAD_OUT="$(mktemp)"
  "$LIB_DIR/load_test.sh" "$ENGINE" run "$1" "$2" "$ENV" >"$LOAD_OUT" 2>&1 &
  LOAD_PID=$!
  LOAD_EPOCH="$(date +%s)"
  TESTID=""
  for _ in $(seq 1 30); do
    TESTID="$(grep -m1 -oE '^Job k6-[a-z]+-run-[0-9-]+' "$LOAD_OUT" | sed 's/^Job k6-//')"
    [[ -n "$TESTID" ]] && break
    sleep 1
  done
  [[ -n "$TESTID" ]] || die "the load did not start: $(cat "$LOAD_OUT")"
  echo "  k6 run $TESTID; 60 s to settle"
  sleep 60
}
load_finish() {
  local job_end
  step "Waiting for the load to finish"
  wait "$LOAD_PID"
  sleep 10 # k6 pushes to Prometheus every 5 s
  echo "  The background load's own output follows. Its SLO verdict is not used: $1"
  sed 's/^/  | /' "$LOAD_OUT"
  rm -f "$LOAD_OUT"
  job_end="$(k -n "$NS" get job "k6-$TESTID" -o jsonpath='{.status.completionTime}{.status.conditions[?(@.type=="Failed")].lastTransitionTime}')"
  END_EPOCH=0
  [[ -n "$job_end" ]] && END_EPOCH="$(date -u -j -f %Y-%m-%dT%H:%M:%SZ "$job_end" +%s)"
  return 0
}
k6_count() { prom_value "sum(max_over_time($1{testid=\"$TESTID\"$2}[2h]${3:+ @ $3}))"; }
# Each push that raised the failure count, from the load's start to its end
k6_fail_window() {
  local q="sum(k6_http_reqs_total{testid=\"$TESTID\",expected_response=\"false\"$1})"
  k get --raw "/api/v1/namespaces/monitoring/services/kube-prometheus-stack-prometheus:http-web/proxy/api/v1/query_range?query=$(printf %s "$q" | jq -sRr @uri)&start=$LOAD_EPOCH&end=$END_EPOCH&step=5" 2>/dev/null |
    jq -r '(.data.result[0].values // []) as $v
      | [range($v | length) | select(. == 0 or ($v[.][1] | tonumber) > ($v[. - 1][1] | tonumber)) | $v[.][0] | floor]
      | select(length > 0) | "\(first) \(last)"'
}
WRITES=',op=~"create|update|delete"'
READS=',op=~"read|search"'
# judge_writes <cutoff epoch>: prints the write and read totals, then fails
# on a lost write, on any write failing after the cutoff, or on a load that
# ended too soon after it to show anything
judge_writes() {
  local cutoff="$1" ok failed failed_by lost rfailed rfailed_by
  ok="$(k6_count k6_http_reqs_total "$WRITES,expected_response=\"true\"")"
  failed="$(k6_count k6_http_reqs_total "$WRITES,expected_response=\"false\"")"
  failed_by="$(k6_count k6_http_reqs_total "$WRITES,expected_response=\"false\"" "$cutoff")"
  rfailed="$(k6_count k6_http_reqs_total "$READS,expected_response=\"false\"")"
  rfailed_by="$(k6_count k6_http_reqs_total "$READS,expected_response=\"false\"" "$cutoff")"
  lost="$(k6_count k6_orders_lost_total '')"
  echo "  Writes: $ok succeeded, $failed failed ($((failed - failed_by)) after $(date -u -r "$cutoff" +%H:%M:%S)); $lost acknowledged writes lost"
  echo "  Reads and searches failed: $rfailed ($((rfailed - rfailed_by)) after $(date -u -r "$cutoff" +%H:%M:%S))"
  [[ "$ok" -gt 0 ]] || die "no successful writes found for $TESTID in Prometheus: the check would prove nothing"
  [[ "$lost" -eq 0 ]] || die "$lost acknowledged writes were lost (RPO must be 0)"
  [[ "$failed" -eq "$failed_by" ]] || die "writes still failed after $(date -u -r "$cutoff" +%H:%M:%S)"
  [[ "$rfailed" -eq "$rfailed_by" ]] || die "reads still failed after $(date -u -r "$cutoff" +%H:%M:%S)"
  [[ "$END_EPOCH" -gt $((cutoff + 60)) ]] || die "the load ended less than 60 s after the cutoff: rerun with a longer duration"
  WRITES_FAILED="$failed" READS_FAILED="$rfailed"
}

verify_check() {
  local out rc
  step "Verify: relational check_resources.sh"
  out="$("$LIB_DIR/check_resources.sh" "$ENV" 2>&1)"
  rc=$?
  tail -3 <<<"$out" | sed 's/^/  /'
  [[ "$rc" -eq 0 ]] || die "check_resources.sh failed: $(grep -i fail <<<"$out" | head -5)"
}
