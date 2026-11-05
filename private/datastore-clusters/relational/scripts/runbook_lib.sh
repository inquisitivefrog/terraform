# Shared by the relational runbook scripts (runbook_<n>_*.sh); sourced, not
# run. Each script sets ENGINE (pg|mysql) and ENV, then sources this, which
# picks the cluster and opens the script's log.
#   runbook_start <n> "$@"        cluster, log, MY_ROOT_PW for mysql. A script
#                                 run in phases sets RUNBOOK_PHASE first, so
#                                 each phase keeps its own newest log
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
#   judge_writes <cutoff>         0 lost; no write or read failed after
#                                 <cutoff>, except searches the app's
#                                 statement time limit cancelled (counted)
#   APP_PODS                      label selector for the app's pods (not k6's,
#                                 which share the instance label)
#   app_restarts                  restarts of the app's pods, summed
#   verify_check                  relational check_resources.sh passes
# Temporary clusters restored beside the live one (runbooks 8 and 9):
#   vm_free_mib                   the Docker VM's memory not used by containers
#   wait_for <seconds> <cmd...>   retry every 10 s; prints how long it took
#   fingerprint <pod>             per table "table rows max_id checksum"
#   my_nonwriter                  a node HAProxy is not sending writes to
#   restore_absent <target>       stop if <target> is left from an earlier run
#   restore_hint <target>         the commands that delete it by hand
#   restore_pg <target> [time]    a new Cluster from the store (to a time);
#                                 sets TARGET_POD
#   restore_my <target> <destination> [date]   a new one-node PXC cluster,
#                                 then a restore of the backup (to a date);
#                                 sets TARGET_POD, RESTORE
#   restore_consistent <pod>      amcheck (pg) / CHECK TABLE (mysql)
#   restore_app_queries <target> <pod>   a read and a rolled-back write as
#                                 the app user, over TLS, via its endpoint
#   restore_delete <target>       delete it; report anything left
# The backup store (runbooks 7 and 12), with an engine's own key:
#   s3 <identity> <path>          a GET (pg or mysql)
#   inventory <identity> <bucket> every object: key, size, modified (tabs)
#   mib <bytes>                   "<n> MiB"

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
  runbook_log "$LIB_DIR/../logs" "runbook-$n-$ENGINE${RUNBOOK_PHASE:+-$RUNBOOK_PHASE}" "$@"
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
# search_timeouts <from epoch>: the app's failed requests since then that
# its statement time limit cancelled (ApiErrors logs one line per failed
# request; mysql max_execution_time, pg statement_timeout)
search_timeouts() {
  local since pod n=0
  since="$(date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ)"
  for pod in $(k -n "$NS" get pods -l "$APP_PODS" -o name); do
    n=$((n + $(k -n "$NS" logs "$pod" -c orders --since-time="$since" 2>/dev/null |
      grep 'database unavailable' | grep -cE 'maximum statement execution time exceeded|canceling statement due to statement timeout')))
  done
  echo "$n"
}
# judge_writes <cutoff epoch>: prints the write and read totals, then fails
# on a lost write, on any write failing after the cutoff, on a read failing
# after it (a search cancelled by the statement time limit excepted: while
# runbook 17's index is missing every search scans the table, and a burst of
# them can pass 5 s on mysql with no fault; 2026-11-05, runbook 22), or on a
# load that ended too soon after it to show anything
judge_writes() {
  local cutoff="$1" ok failed failed_by lost rfailed rfailed_by sfailed sfailed_by timeouts excused
  ok="$(k6_count k6_http_reqs_total "$WRITES,expected_response=\"true\"")"
  failed="$(k6_count k6_http_reqs_total "$WRITES,expected_response=\"false\"")"
  failed_by="$(k6_count k6_http_reqs_total "$WRITES,expected_response=\"false\"" "$cutoff")"
  rfailed="$(k6_count k6_http_reqs_total "$READS,expected_response=\"false\"")"
  rfailed_by="$(k6_count k6_http_reqs_total "$READS,expected_response=\"false\"" "$cutoff")"
  sfailed="$(k6_count k6_http_reqs_total ',op="search",expected_response="false"')"
  sfailed_by="$(k6_count k6_http_reqs_total ',op="search",expected_response="false"' "$cutoff")"
  lost="$(k6_count k6_orders_lost_total '')"
  timeouts=0
  ((sfailed > sfailed_by)) && timeouts="$(search_timeouts "$cutoff")"
  excused=$((sfailed - sfailed_by < timeouts ? sfailed - sfailed_by : timeouts))
  echo "  Writes: $ok succeeded, $failed failed ($((failed - failed_by)) after $(date -u -r "$cutoff" +%H:%M:%S)); $lost acknowledged writes lost"
  echo "  Reads and searches failed: $rfailed ($((rfailed - rfailed_by)) after $(date -u -r "$cutoff" +%H:%M:%S)$( ((excused > 0)) && echo ", of them $excused searches over the statement time limit: not judged"))"
  [[ "$ok" -gt 0 ]] || die "no successful writes found for $TESTID in Prometheus: the check would prove nothing"
  [[ "$lost" -eq 0 ]] || die "$lost acknowledged writes were lost (RPO must be 0)"
  [[ "$failed" -eq "$failed_by" ]] || die "writes still failed after $(date -u -r "$cutoff" +%H:%M:%S)"
  [[ $((rfailed - rfailed_by - excused)) -eq 0 ]] || die "reads still failed after $(date -u -r "$cutoff" +%H:%M:%S)"
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

# --- temporary restore clusters (runbooks 8 and 9) ---
RESTORE_LIMIT=1800 # seconds for a restore to finish

vm_free_mib() {
  local total used
  total="$(docker info --format '{{.MemTotal}}')"
  used="$(docker stats --no-stream --format '{{.MemUsage}}' | awk '{
    v = $1; u = v; sub(/[0-9.]+/, "", u); sub(/[A-Za-z]+$/, "", v)
    m = (u == "GiB") ? 1024 : (u == "MiB") ? 1 : (u == "KiB") ? 1 / 1024 : 1 / 1048576
    s += v * m } END { printf "%d", s }')"
  echo $((total / 1048576 - used))
}

wait_for() {
  local limit="$1" start=$SECONDS
  shift
  until "$@" >/dev/null 2>&1; do
    ((SECONDS - start >= limit)) && return 1
    sleep 10
  done
  echo "  after $((SECONDS - start)) s"
}

# The checksum is the sum of a hash of every row (pg hashtext, mysql CRC32),
# so it is the same whatever order the rows are stored in.
PG_FP="SELECT 'customers', count(*), coalesce(max(id), 0),
         coalesce(sum(hashtext(concat_ws('|', id, name, email, created_at))), 0) FROM customers
       UNION ALL
       SELECT 'orders', count(*), coalesce(max(id), 0),
         coalesce(sum(hashtext(concat_ws('|', id, request_id, run_id, customer_id, status, total_cents, created_at, updated_at))), 0) FROM orders"
MY_FP="SELECT 'customers', COUNT(*), COALESCE(MAX(id), 0),
         COALESCE(SUM(CRC32(CONCAT_WS('|', id, name, email, created_at))), 0) FROM appdb.customers
       UNION ALL
       SELECT 'orders', COUNT(*), COALESCE(MAX(id), 0),
         COALESCE(SUM(CRC32(CONCAT_WS('|', id, request_id, run_id, customer_id, status, total_cents, created_at, updated_at))), 0) FROM appdb.orders"
# pg_sql <pod> <sql>: as postgres in appdb over the local socket
pg_sql() { k -n "$NS" exec "$1" -c postgres -- psql -XAtq -F ' ' -v ON_ERROR_STOP=1 -d appdb -c "$2"; }
fingerprint() {
  if [[ "$ENGINE" == pg ]]; then pg_sql "$1" "$PG_FP"; else my_sql "$1" "$MY_FP" | tr '\t' ' '; fi
}

my_nonwriter() {
  local writer pod
  writer="$(my_writer)" || return 1
  for pod in mysql-pxc-0 mysql-pxc-1 mysql-pxc-2; do
    [[ "$pod" != "$writer" ]] && echo "$pod" && return 0
  done
}

# restore_hint <target>: the commands that delete it by hand
restore_hint() {
  if [[ "$ENGINE" == pg ]]; then
    echo "  kubectl -n $NS delete clusters.postgresql.cnpg.io $1"
  else
    echo "  kubectl -n $NS delete pxc-restore -l app.kubernetes.io/instance=$1"
    echo "  kubectl -n $NS delete pxc $1 && kubectl -n $NS delete secret $1-secrets internal-$1"
  fi
}
restore_absent() {
  local kind=clusters.postgresql.cnpg.io
  [[ "$ENGINE" == mysql ]] && kind=perconaxtradbclusters.pxc.percona.com
  if k -n "$NS" get "$kind" "$1" >/dev/null 2>&1; then
    echo "  $1 exists from an earlier run; delete it with:"
    restore_hint "$1"
    die "$1 left over"
  fi
}

# Same image, resources and size as pg; the newest base backup before the
# target (or the newest), then the archived WAL up to the target (or all of
# it). No plugins section: it must not archive into the source's path.
restore_pg() {
  local target="$1" time="${2:-}"
  k -n "$NS" get clusters.postgresql.cnpg.io pg -o json | jq --arg name "$target" --arg time "$time" '{
    apiVersion, kind,
    metadata: {name: $name, namespace: .metadata.namespace, labels: {"app.kubernetes.io/part-of": "runbooks"}},
    spec: {
      instances: 1,
      imageName: .spec.imageName,
      resources: .spec.resources,
      storage: {size: .spec.storage.size},
      enableSuperuserAccess: false,
      bootstrap: {recovery: ({source: "origin", database: "appdb", owner: "app"}
        + (if $time == "" then {} else {recoveryTarget: {targetTime: $time}} end))},
      externalClusters: [{name: "origin", plugin: {
        name: "barman-cloud.cloudnative-pg.io",
        parameters: {barmanObjectName: "pg-backups", serverName: "pg"}}}]
    }}' | k apply -f - || die "could not create $target"
  _pg_restored() { [[ "$(k -n "$NS" get clusters.postgresql.cnpg.io "$1" -o jsonpath='{.status.phase} {.status.readyInstances}')" == "Cluster in healthy state 1" ]]; }
  wait_for "$RESTORE_LIMIT" _pg_restored "$target" ||
    die "$target not healthy after ${RESTORE_LIMIT}s: $(k -n "$NS" get clusters.postgresql.cnpg.io "$target" -o jsonpath='{.status.phase}')"
  TARGET_POD="$target-1"
}

# The backup's mysql.user holds the live cluster's system passwords, so the
# new cluster gets a copy of them (never printed). Same images, resources,
# configuration and storage as mysql; one node and one HAProxy (unsafeFlags:
# Percona wants 3); backup storage without a schedule or binlog collector, so
# it never writes to the store. The restore carries the store's S3 settings
# inline: with only storageName, operator 1.20 fails "nil s3 backup status
# storage" (2026-11-03), though the CRD accepts it. With a date, the binlogs
# are replayed up to it (mysqlbinlog --stop-datetime, whole seconds, UTC).
restore_my() {
  local target="$1" dest="$2" date="${3:-}" state last=""
  k -n "$NS" get secret mysql-secrets -o json | jq --arg name "$target-secrets" '{
    apiVersion, kind, type, data,
    metadata: {name: $name, namespace: .metadata.namespace, labels: {"app.kubernetes.io/part-of": "runbooks"}}}' |
    k apply -f - >/dev/null || die "could not copy the system passwords"
  k -n "$NS" get perconaxtradbclusters.pxc.percona.com mysql -o json | jq --arg name "$target" '{
    apiVersion, kind,
    metadata: {name: $name, namespace: .metadata.namespace, labels: {"app.kubernetes.io/part-of": "runbooks"},
      finalizers: ["percona.com/delete-pxc-pods-in-order", "percona.com/delete-pxc-pvc", "percona.com/delete-ssl"]},
    spec: {
      crVersion: .spec.crVersion,
      secretsName: ($name + "-secrets"),
      unsafeFlags: {pxcSize: true, proxySize: true},
      updateStrategy: .spec.updateStrategy,
      upgradeOptions: {apply: "disabled"},
      tls: {enabled: true},
      pxc: {size: 1, image: .spec.pxc.image, autoRecovery: true, configuration: .spec.pxc.configuration,
        resources: .spec.pxc.resources, volumeSpec: .spec.pxc.volumeSpec},
      haproxy: {enabled: true, size: 1, image: .spec.haproxy.image, resources: .spec.haproxy.resources},
      proxysql: {enabled: false}, logcollector: {enabled: false}, pmm: {enabled: false},
      backup: {image: .spec.backup.image, storages: .spec.backup.storages}
    }}' | k apply -f - || die "could not create $target"
  _my_ready() { [[ "$(k -n "$NS" get perconaxtradbclusters.pxc.percona.com "$1" -o jsonpath='{.status.state} {.status.pxc.ready}')" == "ready 1" ]]; }
  printf '  empty cluster ready'
  wait_for 900 _my_ready "$target" || die "$target not ready after 900 s"
  RESTORE="$target-$(date -u +%Y%m%d-%H%M%S)"
  k -n "$NS" get perconaxtradbclusters.pxc.percona.com mysql -o json |
    jq --arg name "$RESTORE" --arg target "$target" --arg dest "$dest" --arg date "$date" '{
    apiVersion, kind: "PerconaXtraDBClusterRestore",
    metadata: {name: $name, namespace: .metadata.namespace,
      labels: {"app.kubernetes.io/part-of": "runbooks", "app.kubernetes.io/instance": $target}},
    spec: ({pxcCluster: $target, backupSource: {destination: $dest, s3: .spec.backup.storages.s3.s3}}
      + (if $date == "" then {} else
          {pitr: {type: "date", date: $date, backupSource: {s3: .spec.backup.storages.s3.s3}}} end))}' |
    k apply -f - || die "could not create the restore"
  local start=$SECONDS
  while :; do
    state="$(k -n "$NS" get perconaxtradbclusterrestores.pxc.percona.com "$RESTORE" -o jsonpath='{.status.state}')"
    [[ "$state" != "$last" ]] && echo "  $(date -u +%H:%M:%S) ${state:-(no status yet)}" && last="$state"
    [[ "$state" == Succeeded ]] && break
    [[ "$state" == Failed || "$state" == Error ]] &&
      die "the restore failed: $(k -n "$NS" get perconaxtradbclusterrestores.pxc.percona.com "$RESTORE" -o jsonpath='{.status.comments}')"
    ((SECONDS - start >= RESTORE_LIMIT)) && die "the restore did not finish in ${RESTORE_LIMIT}s"
    sleep 10
  done
  printf '  restored cluster ready'
  wait_for 600 _my_ready "$target" || die "$target not ready after the restore"
  TARGET_POD="$target-pxc-0"
}

restore_consistent() {
  local n out
  if [[ "$ENGINE" == pg ]]; then
    n="$(pg_sql "$1" "CREATE EXTENSION IF NOT EXISTS amcheck;
      SELECT sum(CASE WHEN bt_index_check(c.oid, true) IS NULL THEN 1 ELSE 1 END) FROM pg_index i
        JOIN pg_class c ON c.oid = i.indexrelid JOIN pg_am a ON a.oid = c.relam
        WHERE a.amname = 'btree' AND c.relnamespace = 'public'::regnamespace")" || die "amcheck found a problem"
    echo "  amcheck: $n B-tree indexes checked against their tables, no errors"
    ((n > 0)) || die "amcheck checked no indexes"
  else
    out="$(my_sql "$1" "CHECK TABLE appdb.customers, appdb.orders")" || die "CHECK TABLE failed to run"
    sed 's/^/  /' <<<"$out"
    [[ "$(awk -F'\t' '$3 == "status" && $4 == "OK"' <<<"$out" | wc -l | tr -d ' ')" == 2 ]] || die "CHECK TABLE did not report OK for both tables"
  fi
}

restore_app_queries() {
  local target="$1" pod="$2" pw out
  local q_read="SELECT count(*) FROM orders WHERE customer_id = (SELECT min(id) FROM customers)"
  if [[ "$ENGINE" == pg ]]; then
    pw="$(k -n "$NS" get secret "$target-app" -o jsonpath='{.data.password}' | base64 -d)"
    out="$(k -n "$NS" exec -i "$pod" -c postgres -- sh -c \
      'read -r PGPASSWORD; export PGPASSWORD; exec psql -XAtq -v ON_ERROR_STOP=1 "host=$0 user=app dbname=appdb sslmode=require connect_timeout=5" -c "$1" -c BEGIN -c "$2" -c ROLLBACK' \
      "$target-rw" "$q_read" "INSERT INTO customers (name, email) VALUES ('runbook', 'runbook@example.com') RETURNING 'write ok'" <<<"$pw")" ||
      die "an application query failed: $out"
  else
    pw="$(k -n "$NS" get secret mysql-custom-user-secret -o jsonpath='{.data.app}' | base64 -d)"
    out="$(k -n "$NS" exec -i "$pod" -c pxc -- sh -c \
      'read -r MYSQL_PWD; export MYSQL_PWD; exec mysql -uapp -h "$0" --ssl-mode=REQUIRED --connect-timeout=5 -D appdb -NBe "$1; $2"' \
      "$target-haproxy" "$q_read" "BEGIN; INSERT INTO customers (name, email) VALUES ('runbook', 'runbook@example.com'); SELECT 'write ok'; ROLLBACK" <<<"$pw")" ||
      die "an application query failed: $out"
  fi
  sed 's/^/  /' <<<"$out"
  [[ "$out" == *"write ok"* ]] || die "the write did not succeed"
}

restore_delete() {
  local target="$1" left
  if [[ "$ENGINE" == pg ]]; then
    k -n "$NS" delete clusters.postgresql.cnpg.io "$target" --wait=true --timeout=300s >/dev/null || die "could not delete $target"
  else
    k -n "$NS" delete perconaxtradbclusterrestores.pxc.percona.com -l "app.kubernetes.io/instance=$target" >/dev/null
    k -n "$NS" delete perconaxtradbclusters.pxc.percona.com "$target" --wait=true --timeout=300s >/dev/null || die "could not delete $target"
    k -n "$NS" delete secret "$target-secrets" "internal-$target" --ignore-not-found >/dev/null
  fi
  # By label, not name: the live cluster's binlog collector is "mysql-pitr"
  # (2026-11-03, a name clash with runbook 9's first target name)
  local sel="app.kubernetes.io/instance=$target"
  [[ "$ENGINE" == pg ]] && sel="cnpg.io/cluster=$target"
  _restore_gone() { [[ -z "$(k -n "$NS" get pods,pvc -l "$1" -o name)" ]]; }
  wait_for 300 _restore_gone "$sel" || die "pods or volumes of $target are still there: $(k -n "$NS" get pods,pvc -l "$sel" -o name | xargs)"
  left="$(k -n "$NS" get secrets,certificates.cert-manager.io,issuers.cert-manager.io -o name 2>/dev/null | grep -- "$target" | xargs)"
  if [[ -z "$left" ]]; then echo "  nothing of $target left"; else echo "  left over (harmless, delete by hand): $left"; fi
}

# --- the backup store ---
KEYS="$HOME/.config/datastore-dev/backup-store/s3.json"
# s3 <identity> <path>: a GET against the store with that identity's key
# (handed to curl on stdin, never printed). The path is percent-encoded:
# curl's signing fails on a raw colon (MySQL's backup names have them).
s3() {
  python3 - "$KEYS" "$@" <<'EOF'
import json, os, subprocess, sys, urllib.parse
keys, identity, path = sys.argv[1:]
c = next(i for i in json.load(open(keys))["identities"] if i["name"] == identity)["credentials"][0]
p, q = (path.split("?", 1) + [""])[:2]
path = urllib.parse.quote(p) + ("?" + q if q else "")
r = subprocess.run(["curl", "-s", "--aws-sigv4", "aws:amz:us-east-1:s3", "-K", "-", f"https://localhost:8333/{path}"],
                   input=f'user = "{c["accessKey"]}:{c["secretKey"]}"\ncacert = "{os.path.dirname(keys)}/ca.crt"', capture_output=True, text=True)
sys.stdout.write(r.stdout)
EOF
}
# inventory <identity> <bucket>: every object, "key<TAB>size<TAB>modified"
inventory() {
  python3 - "$KEYS" "$@" <<'EOF'
import json, os, re, subprocess, sys, urllib.parse
keys, identity, bucket = sys.argv[1:]
c = next(i for i in json.load(open(keys))["identities"] if i["name"] == identity)["credentials"][0]
token = ""
while True:
    q = "list-type=2" + (("&continuation-token=" + urllib.parse.quote(token)) if token else "")
    page = subprocess.run(["curl", "-s", "--aws-sigv4", "aws:amz:us-east-1:s3", "-K", "-", f"https://localhost:8333/{bucket}?{q}"],
                          input=f'user = "{c["accessKey"]}:{c["secretKey"]}"\ncacert = "{os.path.dirname(keys)}/ca.crt"', capture_output=True, text=True).stdout
    if "<ListBucketResult" not in page:
        sys.exit("listing " + bucket + " failed: " + page[:80])
    for it in re.findall(r"<Contents>(.*?)</Contents>", page, re.S):
        print(re.search(r"<Key>([^<]+)", it).group(1), re.search(r"<Size>(\d+)", it).group(1),
              re.search(r"<LastModified>([^<]+)", it).group(1), sep="\t")
    m = re.search(r"<NextContinuationToken>([^<]+)</NextContinuationToken>", page)
    if "<IsTruncated>true</IsTruncated>" not in page or not m:
        break
    token = m.group(1)
EOF
}
mib() { awk -v b="$1" 'BEGIN { printf "%.0f MiB", b / 1048576 }'; }
