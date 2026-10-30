#!/usr/bin/env bash
# Runbook 1, monitor: fire each tested alert once, on purpose, under load,
# and see it reach Alertmanager and clear again. The rules live with each
# cluster (modules/*/cluster/alerts.tf) and app (modules/orders-app/alerts.tf).
# Repeatable: every trigger is undone, and the cluster is whole between
# tests.
#   0. preconditions: the cluster is whole, the rules are loaded, none of
#      them is firing
#   1. start a k6 run at a quiet rate (default 20 requests/s; 15m for pg,
#      20m for mysql): the lag
#      tests need writes, the SLO alert needs traffic
#   2. member down
#        pg     fence a replica (cnpg.io/fencedInstances: CloudNativePG
#               stops its PostgreSQL and leaves the pod running)
#        mysql  freeze a non-writer's mysqld (SIGSTOP from its node, again
#               each time the kubelet restarts it): a hung node
#   3. replication lag
#        pg     pause WAL replay on a replica (pg_wal_replay_pause)
#        mysql  desync a non-writer and hold FLUSH TABLES WITH READ LOCK,
#               as a backup tool does: write-sets queue up unapplied
#   4. connections over 80%: a pod holds idle connections to a replica
#      (85% of max_connections)
#   5. latency SLO: mysql search misses its 300 ms p95 under load (the
#      planted missing index, runbook 17), so it must fire, and clear once
#      the load ends; pg meets it, so it must stay quiet
#   6. no acknowledged write lost; relational check_resources.sh passes
# Each test: trigger, wait until the alert fires in Prometheus and is in
# Alertmanager, undo, wait until it is no longer firing or pending, wait
# until the cluster is whole. Not fired here (no safe trigger in the lab):
# primary or quorum loss (runbooks 24 and 27), memory, disk, certificates,
# backups.
# Usage: private/datastore-clusters/relational/scripts/runbook_1_alerts.sh pg|mysql [rate] [duration] [dev]
# Log: relational/logs/runbook-1-<engine>-<time>.txt (-FAILED.txt if it fails)

ENGINE="${1:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ ]] || {
  echo "Usage: $0 pg|mysql [rate] [duration] [dev]" >&2
  exit 1
}
RATE="${2:-20}"
# mysql: a frozen node can sit in the kubelet's restart backoff after it
# is thawed, so its tests take longer
[[ "$ENGINE" == pg ]] && DURATION="${3:-15m}" || DURATION="${3:-20m}"
ENV="${4:-dev}"
FIRE_WAIT=300  # seconds for an alert to fire after its trigger
CLEAR_WAIT=420 # seconds for it to clear (a 5m rate window, for the SLO)
source "$(dirname "$0")/runbook_lib.sh"
runbook_start 1 "$@"
[[ "$ENGINE" == pg ]] && CLUSTER=pg || CLUSTER=mysql
APP="orders-$ENGINE"
HOG="alert-test-connections"
VICTIM="" # chosen in step 0; the undo functions run on exit even before then

# --- Prometheus and Alertmanager ---
prom_api() { k get --raw "/api/v1/namespaces/monitoring/services/kube-prometheus-stack-prometheus:http-web/proxy/api/v1/$1"; }
# alert_state <alertname> <matchers>: firing, pending or nothing
alert_state() {
  prom_api "query?query=$(printf %s "ALERTS{alertname=\"$1\"$2}" | jq -sRr @uri)" |
    jq -r '[.data.result[].metric.alertstate] | if any(. == "firing") then "firing" elif any(. == "pending") then "pending" else "" end'
}
# in_alertmanager <alertname>: active copies Alertmanager holds
in_alertmanager() {
  k get --raw "/api/v1/namespaces/monitoring/services/kube-prometheus-stack-alertmanager:http-web/proxy/api/v2/alerts?active=true&filter=$(printf %s "alertname=\"$1\"" | jq -sRr @uri)" | jq length
}
# Every alert of these rules that is firing now, one per line
firing_now() {
  # By the rules' own labels: an alert from count() or min() has no pod
  # or namespace
  prom_api "query?query=$(printf %s "ALERTS{alertstate=\"firing\",cluster=\"$CLUSTER\"} or ALERTS{alertstate=\"firing\",app=\"$APP\"}" | jq -sRr @uri)" |
    jq -r '.data.result[].metric | "\(.alertname) \(.pod // .op // "")"' | sort -u
}

RESULTS=()
# check_alert <alertname> <matchers> <trigger> <undo>
check_alert() {
  local name="$1" sel="$2" t0 fired cleared am
  step "$name: trigger"
  "$3" || die "the trigger for $name failed"
  t0=$SECONDS fired=""
  while ((SECONDS - t0 < FIRE_WAIT)); do
    [[ "$(alert_state "$name" "$sel")" == firing ]] && fired=$((SECONDS - t0)) && break
    sleep 10
  done
  [[ -n "$fired" ]] || { "$4"; die "$name did not fire within $FIRE_WAIT s"; }
  am=0
  for _ in $(seq 1 12); do
    am="$(in_alertmanager "$name")"
    [[ "$am" -gt 0 ]] && break
    sleep 5
  done
  echo "  firing after $fired s; in Alertmanager: $am"
  echo "  firing now: $(firing_now | xargs)"
  [[ "$am" -gt 0 ]] || { "$4"; die "$name fired but never reached Alertmanager"; }
  step "$name: undo"
  "$4" || die "the undo for $name failed"
  t0=$SECONDS cleared=""
  while ((SECONDS - t0 < CLEAR_WAIT)); do
    [[ -z "$(alert_state "$name" "$sel")" ]] && cleared=$((SECONDS - t0)) && break
    sleep 10
  done
  [[ -n "$cleared" ]] || die "$name still active $CLEAR_WAIT s after the undo"
  echo "  cleared after $cleared s"
  wait_whole 600 || die "the cluster is not whole 10 minutes after the undo"
  RESULTS+=("$name: fired after $fired s, cleared $cleared s after the undo")
}

load_running() { kill -0 "$LOAD_PID" 2>/dev/null || die "the load ended before the tests did: rerun with a longer duration"; }

# --- the connection hog: idle sessions held open by a pod ---
# hog_manifest <target ip> <n>: the pod; each client waits on stdin, so its
# session sits idle until the pod goes
hog_manifest() {
  local target_ip="$1" n="$2" image client env
  if [[ "$ENGINE" == pg ]]; then
    image="$(k -n "$NS" get clusters.postgresql.cnpg.io pg -o jsonpath='{.spec.imageName}')"
    client="psql -XAtq \"host=$target_ip user=app dbname=appdb sslmode=require connect_timeout=5\""
    env="{name: PGPASSWORD, valueFrom: {secretKeyRef: {name: pg-app, key: password}}}"
  else
    image="$(k -n "$NS" get perconaxtradbclusters.pxc.percona.com mysql -o jsonpath='{.spec.pxc.image}')"
    client="mysql -uapp -h $target_ip --ssl-mode=REQUIRED --connect-timeout=5 appdb"
    env="{name: MYSQL_PWD, valueFrom: {secretKeyRef: {name: mysql-custom-user-secret, key: app}}}"
  fi
  # A block literal: the client's own quotes would break a quoted string
  cat <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $HOG
  labels: {app: $HOG}
spec:
  restartPolicy: Never
  terminationGracePeriodSeconds: 1
  containers:
    - name: hog
      image: $image
      env: [$env]
      command: [sh, -c]
      args:
        - |
          for i in \$(seq 1 $n); do sleep 3600 | $client >/dev/null 2>&1 & done
          wait
      resources:
        requests: {cpu: 100m, memory: 256Mi}
        limits: {memory: 1Gi}
EOF
}
hog_start() {
  hog_manifest "$1" "$2" | k -n "$NS" apply -f - >/dev/null || return 1
  k -n "$NS" wait --for=condition=Ready "pod/$HOG" --timeout=120s >/dev/null
}
hog_stop() { k -n "$NS" delete pod "$HOG" --ignore-not-found --wait=true >/dev/null; }

# --- engine triggers ---
if [[ "$ENGINE" == pg ]]; then
  pg_local() { k -n "$NS" exec "$1" -c postgres -- psql -XAtq -c "$2"; }
  fence() { k -n "$NS" annotate clusters.postgresql.cnpg.io pg "cnpg.io/fencedInstances=[\"$VICTIM\"]" --overwrite >/dev/null; }
  unfence() { k -n "$NS" annotate clusters.postgresql.cnpg.io pg cnpg.io/fencedInstances- >/dev/null 2>&1 || true; }
  replay_pause() { pg_local "$VICTIM" "SELECT pg_wal_replay_pause()" >/dev/null; }
  replay_resume() { pg_local "$VICTIM" "SELECT pg_wal_replay_resume()" >/dev/null 2>&1 || true; }
  conns_up() {
    local max cur
    max="$(pg_local "$VICTIM" "SHOW max_connections")"
    cur="$(pg_local "$VICTIM" "SELECT count(*) FROM pg_stat_activity WHERE backend_type = 'client backend'")"
    echo "  $VICTIM: $cur of $max connections; opening $((max * 85 / 100 - cur))"
    hog_start "$(k -n "$NS" get pod "$VICTIM" -o jsonpath='{.status.podIP}')" $((max * 85 / 100 - cur))
  }
  undo_all() { unfence; replay_resume; hog_stop; }
else
  NODE_OF() { k -n "$NS" get pod "$1" -o jsonpath='{.spec.nodeName}'; }
  # SIGSTOP from the node: inside the container mysqld is PID 1, which
  # ignores it. A loop, because the liveness probe restarts a hung mysqld.
  FREEZER=""
  freeze() {
    local node
    node="$(NODE_OF "$VICTIM")"
    echo "  freezing mysqld on $node ($VICTIM), again whenever it restarts"
    (while :; do docker exec "$node" pkill -STOP -x mysqld; sleep 5; done) >/dev/null 2>&1 &
    FREEZER=$!
  }
  thaw() {
    [[ -n "$FREEZER" ]] && kill "$FREEZER" 2>/dev/null
    FREEZER=""
    docker exec "$(NODE_OF "$VICTIM")" pkill -CONT -x mysqld 2>/dev/null
    return 0
  }
  LOCKER=""
  desync_lock() {
    my_sql "$VICTIM" "SET GLOBAL wsrep_desync = ON" || return 1
    (my_sql "$VICTIM" "FLUSH TABLES WITH READ LOCK; SELECT SLEEP(1800)") >/dev/null 2>&1 &
    LOCKER=$!
    sleep 5
    [[ -n "$(my_sql "$VICTIM" "SELECT id FROM information_schema.processlist WHERE info LIKE 'SELECT SLEEP(1800)%'")" ]]
  }
  unlock_sync() {
    local id
    for id in $(my_sql "$VICTIM" "SELECT id FROM information_schema.processlist WHERE info LIKE 'SELECT SLEEP(1800)%'" 2>/dev/null); do
      my_sql "$VICTIM" "KILL $id" >/dev/null 2>&1
    done
    [[ -n "$LOCKER" ]] && kill "$LOCKER" 2>/dev/null
    LOCKER=""
    my_sql "$VICTIM" "SET GLOBAL wsrep_desync = OFF" >/dev/null 2>&1
    return 0
  }
  conns_up() {
    local max cur
    max="$(my_sql "$VICTIM" "SELECT @@max_connections")"
    cur="$(my_sql "$VICTIM" "SHOW GLOBAL STATUS LIKE 'Threads_connected'" | awk '{print $2}')"
    echo "  $VICTIM: $cur of $max connections; opening $((max * 85 / 100 - cur))"
    hog_start "$(k -n "$NS" get pod "$VICTIM" -o jsonpath='{.status.podIP}')" $((max * 85 / 100 - cur))
  }
  undo_all() { thaw; unlock_sync; hog_stop; }
fi
# Whatever happens, leave nothing frozen, fenced, paused or locked. In a
# subshell, so an error in an undo cannot stop the log being closed.
trap 'rc=$?; (undo_all) >/dev/null 2>&1; _runbook_log_end "$rc"; exit "$rc"' EXIT

# --- 0. preconditions ---
step "0. Preconditions"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
# A rule just applied takes a minute or two to reach Prometheus (the
# operator writes it to a ConfigMap, the config reloader picks it up)
groups_loaded() { prom_api rules | jq -r '.data.groups[].name' | grep -cxE "(postgresql-pg|mysql-mysql|orders-pg|orders-mysql)"; }
for _ in $(seq 1 36); do
  [[ "$(groups_loaded)" -eq 4 ]] && break
  sleep 5
done
[[ "$(groups_loaded)" -eq 4 ]] || die "Prometheus has $(groups_loaded) of the 4 relational rule groups after 3 minutes: apply the clusters and app roots"
[[ -z "$(firing_now)" ]] || die "alerts already firing: $(firing_now | xargs)"
if [[ "$ENGINE" == pg ]]; then
  read -r -a REPLICAS <<<"$(pg_replicas)"
  VICTIM="${REPLICAS[0]}"
  echo "  primary $(pg_primary); tests on replica $VICTIM"
else
  WRITER="$(my_writer)"
  for pod in mysql-pxc-0 mysql-pxc-1 mysql-pxc-2; do
    [[ "$pod" != "$WRITER" ]] && VICTIM="$pod" && break
  done
  echo "  writer $WRITER; tests on $VICTIM"
fi
echo "  rule groups loaded: 4; none firing"

# --- 1. load ---
load_start "$RATE" "$DURATION"

# --- 2-4. the cluster's alerts ---
SEL=",cluster=\"$CLUSTER\""
if [[ "$ENGINE" == pg ]]; then
  check_alert PostgreSQLInstanceDown "$SEL" fence unfence
  load_running
  check_alert PostgreSQLReplicationLag "$SEL,pod=\"$VICTIM\"" replay_pause replay_resume
  load_running
  check_alert PostgreSQLConnectionsHigh "$SEL,pod=\"$VICTIM\"" conns_up hog_stop
else
  check_alert MySQLMemberDown "$SEL" freeze thaw
  load_running
  check_alert MySQLApplyQueue "$SEL,pod=\"$VICTIM\"" desync_lock unlock_sync
  load_running
  check_alert MySQLConnectionsHigh "$SEL,pod=\"$VICTIM\"" conns_up hog_stop
fi

# --- 5. the SLO alert ---
step "5. Latency SLO alert for $APP search"
load_running
SLO_SEL=",app=\"$APP\",op=\"search\""
SLO_STATE="$(alert_state OrdersLatencySLO "$SLO_SEL")"
echo "  now: ${SLO_STATE:-not active}"
if [[ "$ENGINE" == mysql ]]; then
  [[ "$SLO_STATE" == firing ]] || die "OrdersLatencySLO for $APP search is not firing, though search misses its SLO under load"
  [[ "$(in_alertmanager OrdersLatencySLO)" -gt 0 ]] || die "OrdersLatencySLO fired but is not in Alertmanager"
  echo "  firing and in Alertmanager"
else
  [[ -z "$SLO_STATE" ]] || die "OrdersLatencySLO for $APP search is $SLO_STATE, though PostgreSQL search meets its SLO at $RATE requests/s"
fi

load_finish "search fails by design on mysql (runbook 17), and the triggers above
  may slow requests. This step judges lost writes only."
LOST="$(k6_count k6_orders_lost_total '')"
echo "  Writes failed: $(k6_count k6_http_reqs_total "$WRITES,expected_response=\"false\""); reads failed: $(k6_count k6_http_reqs_total "$READS,expected_response=\"false\""); acknowledged writes lost: $LOST"
[[ "$LOST" -eq 0 ]] || die "$LOST acknowledged writes were lost"
if [[ "$ENGINE" == mysql ]]; then
  t0=$SECONDS
  while [[ -n "$(alert_state OrdersLatencySLO "$SLO_SEL")" ]]; do
    ((SECONDS - t0 >= CLEAR_WAIT)) && die "OrdersLatencySLO still active $CLEAR_WAIT s after the load ended"
    sleep 10
  done
  RESULTS+=("OrdersLatencySLO (search): firing under load, cleared $((SECONDS - t0)) s after the load ended")
else
  RESULTS+=("OrdersLatencySLO (search): stayed quiet, as PostgreSQL search meets its SLO")
fi

# --- 6. verify ---
verify_check
[[ -z "$(firing_now)" ]] || die "alerts still firing at the end: $(firing_now | xargs)"
step "Results"
printf '  %s\n' "${RESULTS[@]}"
step "Runbook 1 ($ENGINE): passed"
