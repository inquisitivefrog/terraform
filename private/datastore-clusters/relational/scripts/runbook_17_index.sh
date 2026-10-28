#!/usr/bin/env bash
# Runbook 17 for the planted missing index: add it online, under load, and
# prove it. One index serves both search shapes, (customer_id, created_at,
# id): each search filters one customer and wants the newest 20, so the
# index walks that customer's orders newest first and checks status on the
# way (about 1 in 5 match). A (customer_id, status) index would serve only
# the first shape.
# Repeatable: it starts from the planted problem and puts it back, so every
# run exercises the whole change.
#   0. preconditions; an index left by an earlier run is dropped first
#   1. before: both search plans scan the whole table
#   2. start a k6 run at a quiet rate (default 20 requests/s); 60 s to settle
#   3. add the index without blocking writes
#        pg     CREATE INDEX CONCURRENTLY, lock_timeout 5 s; an index left
#               INVALID by a failed attempt is dropped and the build retried
#        mysql  pt-online-schema-change: a copy of the table filled in chunks
#               behind triggers, pausing on Galera flow control, then swapped
#               in. Not a plain ALTER: Galera runs DDL in total order, and
#               every node stops applying writes until the build finishes.
#   4. no write failed and no acknowledged write was lost while it ran
#      (k6's results in Prometheus); the change ended before the load did
#   5. after: the plans use the index, on every node
#   6. verify: the load that failed before (150 requests/s for 5 m) meets
#      every SLO
#   7. restore: drop the index again (unless --keep) and confirm the plans
#      scan again; runs even when 6 fails
# Usage: private/datastore-clusters/relational/scripts/runbook_17_index.sh [--keep] pg|mysql [rate] [duration] [dev]
#   rate, duration  the load during the change (default 20 requests/s; 4m
#                   for pg, 15m for mysql: pt-online-schema-change copies
#                   the whole table)
#   --keep          leave the index in place at the end (the real fix)
# Changes the schema, then changes it back.
# Log: relational/logs/runbook-17-<engine>-<time>.txt (-FAILED.txt if it fails)

set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/../../../scripts/private_env.sh" # use_cluster, k, runbook_log
source "$DIR/../../../scripts/checks.sh"      # prom_value

PT_IMAGE="percona/percona-toolkit:3.7.1-4" # 3.7.2 (2026-10-22) is days old
KEEP=""
[[ "${1:-}" == --keep ]] && KEEP=1 && shift
ENGINE="${1:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ ]] || {
  echo "Usage: $0 [--keep] pg|mysql [rate] [duration] [dev]" >&2
  exit 1
}
RATE="${2:-20}"
[[ "$ENGINE" == pg ]] && DURATION="${3:-4m}" || DURATION="${3:-15m}"
ENV="${4:-dev}"
NS="relational"
INDEX="orders_customer_created_idx"
INDEX_COLUMNS="customer_id, created_at, id"

use_cluster "datastore-$ENV"
runbook_log "$DIR/../logs" "runbook-17-$ENGINE" ${KEEP:+--keep} "$@"

step() { echo; echo "== $(date -u +%H:%M:%S) $*"; }
die() { echo "FAILED: $*"; exit 1; }
secret() { k -n "$NS" get secret "$1" -o jsonpath="{.data.$2}" | base64 -d; }

# --- PostgreSQL: as postgres over each instance's local socket ---
pg_sql() {
  local pod="$1"
  shift
  k -n "$NS" exec "$pod" -c postgres -- psql -XAtq -d appdb -v ON_ERROR_STOP=1 "$@"
}
# t (valid), f (invalid: a failed concurrent build) or empty (none)
pg_index_state() { pg_sql "$1" -c "SELECT indisvalid FROM pg_index WHERE indexrelid = to_regclass('public.$INDEX')"; }
pg_plans() {
  local pod="$1" shape sql
  for shape in "customer and status|status = 'PAID'" "customer, last 30 days|created_at >= now() - interval '30 days'"; do
    sql="EXPLAIN (ANALYZE, COSTS off) SELECT * FROM orders WHERE customer_id = $CUSTOMER AND ${shape#*|} ORDER BY created_at DESC, id DESC LIMIT 20"
    echo "  ${shape%%|*} ($pod):"
    pg_sql "$pod" -c "$sql" | grep -E 'Scan|Execution Time' | sed 's/^/    /'
  done
}
pg_drop_index() {
  local attempt
  for attempt in 1 2 3; do
    pg_sql "$PG_PRIMARY" -c "SET lock_timeout = '5s'" -c "DROP INDEX CONCURRENTLY IF EXISTS $INDEX" && return 0
    sleep 5
  done
  return 1
}
pg_add_index() {
  local attempt
  for attempt in 1 2 3; do
    case "$(pg_index_state "$PG_PRIMARY")" in
      t) return 0 ;;
      f)
        echo "  An INVALID $INDEX is left from a failed build: dropping it"
        pg_sql "$PG_PRIMARY" -c "SET lock_timeout = '5s'" -c "DROP INDEX CONCURRENTLY IF EXISTS $INDEX"
        ;;
    esac
    echo "  Attempt $attempt: CREATE INDEX CONCURRENTLY $INDEX ON orders ($INDEX_COLUMNS)"
    pg_sql "$PG_PRIMARY" -c "SET lock_timeout = '5s'" -c "SET statement_timeout = 0" \
      -c "CREATE INDEX CONCURRENTLY $INDEX ON orders ($INDEX_COLUMNS)" && return 0
    sleep 10
  done
  return 1
}

# --- MySQL: as root over each node's local socket; password on stdin ---
my_node() {
  k -n "$NS" exec -i "$1" -c pxc -- sh -c \
    'read -r MYSQL_PWD; export MYSQL_PWD; exec mysql -uroot -D appdb -NBre "$0"' "$2" <<<"$MY_ROOT_PW"
}
my_has_index() {
  my_node "$1" "SELECT COUNT(*) > 0 FROM information_schema.statistics
    WHERE table_schema = 'appdb' AND table_name = 'orders' AND index_name = '$INDEX'"
}
my_plans() {
  local pod="$1" shape sql
  for shape in "customer and status|status = 'PAID'" "customer, last 30 days|created_at >= NOW(6) - INTERVAL 30 DAY"; do
    sql="EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = $CUSTOMER AND ${shape#*|} ORDER BY created_at DESC, id DESC LIMIT 20"
    echo "  ${shape%%|*} ($pod):"
    my_node "$pod" "$sql" | sed -E 's/  \(cost=[^)]*\)//' | cut -c1-150 | head -6 | sed 's/^/    /'
  done
}
# Dropping an index is metadata only in InnoDB (ALGORITHM=INPLACE: no table
# copy), so a plain ALTER is brief even though Galera runs it on every node in
# total order. No LOCK clause: PXC refuses LOCK=NONE here (error 1845, "Try
# LOCK=SHARED"), and TOI pauses the cluster for any DDL anyway. A short lock
# wait keeps it from queueing behind a long transaction, and it is retried.
my_drop_index() {
  local attempt
  for attempt in 1 2 3; do
    my_node "${MY_NODES[0]}" "SET SESSION lock_wait_timeout = 5;
      ALTER TABLE orders DROP INDEX $INDEX, ALGORITHM=INPLACE" && return 0
    sleep 5
  done
  return 1
}
# pt_osc --dry-run|--execute: pt-online-schema-change as a Job, through the
# writer HAProxy over TLS; root's password reaches it as a file from the Secret
pt_osc() {
  local job="pt-osc-orders-$(date -u +%Y%m%d-%H%M%S)" mode="$1"
  k -n "$NS" apply -f - >/dev/null <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $job
  labels: {app.kubernetes.io/name: pt-osc, app.kubernetes.io/instance: mysql}
spec:
  backoffLimit: 0
  activeDeadlineSeconds: 3600
  ttlSecondsAfterFinished: 86400
  template:
    metadata:
      labels: {app.kubernetes.io/name: pt-osc, app.kubernetes.io/instance: mysql}
    spec:
      restartPolicy: Never
      securityContext: {runAsNonRoot: true, runAsUser: 1001, seccompProfile: {type: RuntimeDefault}}
      containers:
        - name: pt-osc
          image: $PT_IMAGE
          env:
            - name: ROOT_PW
              valueFrom: {secretKeyRef: {name: mysql-secrets, key: root}}
          command: [sh, -c]
          args:
            - |
              umask 077
              printf '[client]\nuser=root\npassword="%s"\n' "\$ROOT_PW" > /tmp/my.cnf
              exec pt-online-schema-change $mode \\
                --alter "ADD INDEX $INDEX ($INDEX_COLUMNS)" \\
                --recursion-method=none --max-flow-ctl=0.5 --chunk-time 0.1 \\
                --max-load Threads_running=50 --critical-load Threads_running=200 \\
                --set-vars lock_wait_timeout=2 \\
                --tries create_triggers:30:2,swap_tables:30:2,drop_triggers:30:2 \\
                --progress time,30 \\
                h=mysql-haproxy,P=3306,D=appdb,t=orders,F=/tmp/my.cnf,s=1
          resources:
            requests: {cpu: 200m, memory: 128Mi}
            limits: {memory: 256Mi}
          securityContext: {allowPrivilegeEscalation: false, readOnlyRootFilesystem: true, capabilities: {drop: [ALL]}}
          volumeMounts: [{name: tmp, mountPath: /tmp}]
      volumes:
        - {name: tmp, emptyDir: {medium: Memory, sizeLimit: 1Mi}}
EOF
  echo "  Job $job: pt-online-schema-change $mode"
  # Follow the log once the container has started (a dry run can finish
  # before a Ready check would see it), then wait for the Job's verdict for
  # as long as the copy takes: activeDeadlineSeconds bounds it.
  local phase status
  for _ in $(seq 1 90); do
    phase="$(k -n "$NS" get pods -l "job-name=$job" -o jsonpath='{.items[0].status.phase}' 2>/dev/null)"
    [[ -n "$phase" && "$phase" != Pending ]] && break
    sleep 2
  done
  k -n "$NS" logs -f "job/$job" | sed 's/^/    /'
  while :; do
    status="$(k -n "$NS" get job "$job" -o jsonpath='{.status.succeeded}/{.status.failed}')"
    [[ "$status" != "/" ]] && break
    sleep 5
  done
  [[ "$status" == 1/* ]]
}

# --- 0. the cluster is whole before anything changes ---
step "0. Preconditions"
if [[ "$ENGINE" == pg ]]; then
  PG_PRIMARY="$(k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.status.currentPrimary}')"
  read -r -a PG_REPLICAS <<<"$(k -n "$NS" get pods -l cnpg.io/cluster=pg,cnpg.io/instanceRole=replica -o jsonpath='{.items[*].metadata.name}')"
  [[ -n "$PG_PRIMARY" && "${#PG_REPLICAS[@]}" -eq 2 ]] || die "pg needs a primary and 2 replicas (have '$PG_PRIMARY', ${PG_REPLICAS[*]:-none})"
  [[ "$(pg_sql "$PG_PRIMARY" -c "SELECT count(*) FROM pg_stat_replication WHERE state = 'streaming'")" == 2 ]] ||
    die "both replicas must be streaming"
  CUSTOMER="$(pg_sql "$PG_PRIMARY" -c "SELECT customer_id FROM orders ORDER BY id DESC LIMIT 1")"
  ROWS="$(pg_sql "$PG_PRIMARY" -c "SELECT reltuples::bigint FROM pg_class WHERE relname = 'orders'")"
  STATE="$(pg_index_state "$PG_PRIMARY")"
  echo "  primary $PG_PRIMARY, replicas ${PG_REPLICAS[*]} streaming; orders ~$ROWS rows; index: ${STATE:-none}"
else
  MY_ROOT_PW="$(secret mysql-secrets root)"
  read -r -a MY_NODES <<<"$(k -n "$NS" get pods -l app.kubernetes.io/instance=mysql,app.kubernetes.io/component=pxc -o jsonpath='{.items[*].metadata.name}')"
  [[ "$(k -n "$NS" get perconaxtradbclusters.pxc.percona.com mysql -o jsonpath='{.status.state} {.status.pxc.ready}')" == "ready 3" ]] ||
    die "the PXC cluster must be ready with 3 nodes"
  [[ "$(my_node "${MY_NODES[0]}" "SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'wsrep_cluster_size'")" == 3 ]] ||
    die "Galera must have 3 members"
  LEFTOVERS="$(my_node "${MY_NODES[0]}" "SELECT CONCAT_WS(' ', (SELECT GROUP_CONCAT(table_name) FROM information_schema.tables
      WHERE table_schema = 'appdb' AND table_name IN ('_orders_new', '_orders_old')),
    (SELECT GROUP_CONCAT(trigger_name) FROM information_schema.triggers WHERE event_object_schema = 'appdb'))")"
  [[ -z "$LEFTOVERS" ]] || die "an interrupted pt-online-schema-change left: $LEFTOVERS (drop its triggers first, then the _orders_new table)"
  CUSTOMER="$(my_node "${MY_NODES[0]}" "SELECT customer_id FROM orders ORDER BY id DESC LIMIT 1")"
  ROWS="$(my_node "${MY_NODES[0]}" "SELECT table_rows FROM information_schema.tables WHERE table_schema = 'appdb' AND table_name = 'orders'")"
  STATE="$(my_has_index "${MY_NODES[0]}")"
  [[ "$STATE" == 1 ]] && STATE=t || STATE=""
  echo "  nodes ${MY_NODES[*]}, Galera 3 members; orders ~$ROWS rows; index: ${STATE:-none}"
fi
[[ "$CUSTOMER" =~ ^[0-9]+$ ]] || die "no orders to search (seed first: load_test.sh $ENGINE seed)"
if [[ -n "$STATE" ]]; then
  echo "  $INDEX is already there (an earlier run, or --keep): dropping it, so this run starts from the planted problem"
  if [[ "$ENGINE" == pg ]]; then pg_drop_index; else my_drop_index; fi || die "could not drop $INDEX"
fi

# --- 1. before ---
step "1. Before: the search plans (customer $CUSTOMER)"
if [[ "$ENGINE" == pg ]]; then pg_plans "${PG_REPLICAS[0]}"; else my_plans "${MY_NODES[1]}"; fi

{
  # --- 2. load ---
  step "2. Load during the change: $RATE requests/s for $DURATION"
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

  # --- 3. the change ---
  step "3. Add $INDEX ($INDEX_COLUMNS)"
  T0=$(date +%s)
  if [[ "$ENGINE" == pg ]]; then
    pg_add_index || die "CREATE INDEX CONCURRENTLY failed 3 times"
  else
    pt_osc --dry-run || die "pt-online-schema-change --dry-run failed: nothing was changed"
    pt_osc --execute || die "pt-online-schema-change failed (it removes its triggers and copy on failure; step 0 checks)"
  fi
  T1=$(date +%s)
  echo "  Done in $((T1 - T0)) s"

  # --- 4. what the load saw ---
  step "4. Waiting for the load to finish"
  wait "$LOAD_PID"
  sleep 10 # k6 pushes to Prometheus every 5 s
  echo "  The background load's own output follows. Its SLO verdict is not used: searches are"
  echo "  slow until the index exists. This step judges only failed and lost writes."
  sed 's/^/  | /' "$LOAD_OUT"
  JOB_END="$(k -n "$NS" get job "k6-$TESTID" -o jsonpath='{.status.completionTime}{.status.conditions[?(@.type=="Failed")].lastTransitionTime}')"
  q() { prom_value "sum(max_over_time($1{testid=\"$TESTID\"$2}[2h]))"; }
  WRITES_OK="$(q k6_http_reqs_total ',op=~"create|update|delete",expected_response="true"')"
  WRITES_FAILED="$(q k6_http_reqs_total ',op=~"create|update|delete",expected_response="false"')"
  LOST="$(q k6_orders_lost_total '')"
  echo "  During the run: $WRITES_OK writes succeeded, $WRITES_FAILED failed, $LOST acknowledged writes lost"
  echo "  The change ran $(date -u -r "$T0" +%H:%M:%S)-$(date -u -r "$T1" +%H:%M:%S); the load ended ${JOB_END:-?}"
  [[ "$WRITES_OK" -gt 0 ]] || die "no successful writes found for $TESTID in Prometheus: the check would prove nothing"
  [[ -n "$JOB_END" && "$(date -u -j -f %Y-%m-%dT%H:%M:%SZ "$JOB_END" +%s)" -gt "$T1" ]] ||
    die "the change outlasted the load: rerun with a longer duration"
  [[ "$WRITES_FAILED" -eq 0 && "$LOST" -eq 0 ]] || die "writes failed or were lost during the change"
  rm -f "$LOAD_OUT"
}

# --- 5. after ---
step "5. After: the index on every node, and the plans"
if [[ "$ENGINE" == pg ]]; then
  for pod in "$PG_PRIMARY" "${PG_REPLICAS[@]}"; do
    for _ in $(seq 1 30); do
      [[ "$(pg_index_state "$pod")" == t ]] && break
      sleep 2
    done
    [[ "$(pg_index_state "$pod")" == t ]] || die "$INDEX is not valid on $pod"
    echo "  $pod: $INDEX valid"
  done
  pg_plans "${PG_REPLICAS[0]}"
else
  for pod in "${MY_NODES[@]}"; do
    [[ "$(my_has_index "$pod")" == 1 ]] || die "$INDEX is missing on $pod"
    echo "  $pod: $INDEX present"
  done
  my_plans "${MY_NODES[1]}"
fi

# --- 6. verify ---
step "6. Verify: 150 requests/s for 5m, every SLO"
VERIFIED=1
"$DIR/load_test.sh" "$ENGINE" run 150 5m "$ENV" || VERIFIED=""
echo "  Most connections waiting per app pod in the last 6 m (runbook 40 expects 0):"
for pool in reader writer; do
  echo "    $pool: $(prom_value "max(max_over_time(hikaricp_connections_pending{namespace=\"$NS\",pod=~\"orders-$ENGINE-.*\",pool=\"$pool\"}[6m]))")"
done

# --- 7. restore ---
if [[ -n "$KEEP" ]]; then
  step "7. Restore: skipped (--keep): $INDEX stays"
else
  step "7. Restore the planted problem: drop $INDEX"
  if [[ "$ENGINE" == pg ]]; then
    pg_drop_index || die "could not drop $INDEX (the next run drops it first)"
    for pod in "$PG_PRIMARY" "${PG_REPLICAS[@]}"; do
      for _ in $(seq 1 30); do
        [[ -z "$(pg_index_state "$pod")" ]] && break
        sleep 2
      done
      [[ -z "$(pg_index_state "$pod")" ]] || die "$INDEX is still on $pod"
    done
    echo "  Gone from ${PG_PRIMARY} ${PG_REPLICAS[*]}"
    pg_plans "${PG_REPLICAS[0]}"
  else
    my_drop_index || die "could not drop $INDEX (the next run drops it first)"
    for pod in "${MY_NODES[@]}"; do
      [[ "$(my_has_index "$pod")" == 0 ]] || die "$INDEX is still on $pod"
    done
    echo "  Gone from ${MY_NODES[*]}"
    my_plans "${MY_NODES[1]}"
  fi
fi

[[ -n "$VERIFIED" ]] || die "the verify load missed an SLO"
step "Runbook 17 ($ENGINE): passed"
