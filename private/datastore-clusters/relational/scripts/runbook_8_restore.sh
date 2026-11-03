#!/usr/bin/env bash
# Runbook 8, restore into a new cluster: prove a backup is real by restoring
# it into a fourth, temporary cluster beside the live one (never over it),
# checking the data matches, and timing it (the realistic RTO).
#   0. preconditions: the cluster is whole; no restore cluster left over;
#      enough free memory in the Docker VM for one more database
#   1. fingerprint the source (per table: rows, highest id, a checksum of
#      every row), take a fresh full backup (backup_now.sh), fingerprint
#      again: they must match, so the backup holds exactly that data (no
#      load may run meanwhile)
#   2. restore it into <cluster>-restore, one instance:
#        pg     a new CloudNativePG Cluster bootstrapped from the store
#               (bootstrap.recovery: the newest base backup, then the
#               archived WAL); it archives nothing itself
#        mysql  a new one-node PXC cluster with the live cluster's system
#               passwords (they are in the backup's data), then a
#               PerconaXtraDBClusterRestore of the backup into it
#      prints how long until the restored cluster is ready
#   3. consistency: pg amcheck on every B-tree index (with heapallindexed);
#      mysql CHECK TABLE; data checksums are on (pg) so every page read
#      by the fingerprint is verified too
#   4. the restored fingerprint equals the source's
#   5. application queries as the app user, over TLS, through the restored
#      cluster's own endpoint: a read and a write (rolled back)
#   6. delete the restore cluster (kept with --keep, or when a step fails,
#      for a look; the next run refuses to start until it is gone)
#   7. verify: relational check_resources.sh passes
# The backup taken in step 1 stays in the store (the last one proven
# restorable); backup_now.sh says how to delete it.
# Usage: private/datastore-clusters/relational/scripts/runbook_8_restore.sh pg|mysql [--keep] [dev]
# Log: relational/logs/runbook-8-<engine>-<time>.txt (-FAILED.txt if it fails)

ENGINE="${1:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ ]] || {
  echo "Usage: $0 pg|mysql [--keep] [dev]" >&2
  exit 1
}
ARGS=("$@")
shift
KEEP=""
[[ "${1:-}" == --keep ]] && KEEP=1 && shift
ENV="${1:-dev}"
TARGET="$ENGINE-restore"
NEED_MIB=3072   # free VM memory needed: the restored database plus its restore job
LIMIT=1800      # seconds for the restore to finish
source "$(dirname "$0")/runbook_lib.sh"
runbook_start 8 "${ARGS[@]}"

# vm_free_mib: the Docker VM's memory minus what every container uses
vm_free_mib() {
  local total used
  total="$(docker info --format '{{.MemTotal}}')"
  used="$(docker stats --no-stream --format '{{.MemUsage}}' | awk '{
    v = $1; u = v; sub(/[0-9.]+/, "", u); sub(/[A-Za-z]+$/, "", v)
    m = (u == "GiB") ? 1024 : (u == "MiB") ? 1 : (u == "KiB") ? 1 / 1024 : 1 / 1048576
    s += v * m } END { printf "%d", s }')"
  echo $((total / 1048576 - used))
}

# wait_for <seconds> <command...>: retry every 10 s; prints how long it took
wait_for() {
  local limit="$1" start=$SECONDS
  shift
  until "$@" >/dev/null 2>&1; do
    ((SECONDS - start >= limit)) && return 1
    sleep 10
  done
  echo "  after $((SECONDS - start)) s"
}

# --- fingerprints: one line per table, "table rows max_id checksum" ---
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
pg_sql() { k -n "$NS" exec "$1" -c postgres -- psql -XAtq -F ' ' -v ON_ERROR_STOP=1 -d appdb -c "$2"; }
fingerprint() {
  if [[ "$ENGINE" == pg ]]; then pg_sql "$1" "$PG_FP"; else my_sql "$1" "$MY_FP" | tr '\t' ' '; fi
}

# --- 0. preconditions ---
step "0. Preconditions"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
if [[ "$ENGINE" == pg ]]; then
  k -n "$NS" get clusters.postgresql.cnpg.io "$TARGET" >/dev/null 2>&1 && die "$TARGET exists from an earlier run: kubectl -n $NS delete clusters.postgresql.cnpg.io $TARGET"
  SOURCE_POD="$(pg_primary)"
else
  k -n "$NS" get perconaxtradbclusters.pxc.percona.com "$TARGET" >/dev/null 2>&1 && die "$TARGET exists from an earlier run: kubectl -n $NS delete pxc $TARGET; kubectl -n $NS delete secret $TARGET-secrets"
  WRITER="$(my_writer)"
  [[ -n "$WRITER" ]] || die "could not ask HAProxy which node is the writer"
  for pod in mysql-pxc-0 mysql-pxc-1 mysql-pxc-2; do
    [[ "$pod" != "$WRITER" ]] && SOURCE_POD="$pod" && break
  done
fi
FREE="$(vm_free_mib)"
echo "  source: $SOURCE_POD; Docker VM memory free: $FREE MiB (need $NEED_MIB)"
((FREE >= NEED_MIB)) || die "not enough free memory for a fifth database: stop something first"
[[ -z "$(k -n "$NS" get jobs -l app.kubernetes.io/name=k6 -o jsonpath='{.items[?(@.status.active)].metadata.name}' 2>/dev/null)" ]] ||
  die "a k6 load is running: the source must be idle for the fingerprints to match"

# --- 1. fingerprint, back up, fingerprint ---
step "1. Fingerprint the source, back it up, fingerprint again"
FP_BEFORE="$(fingerprint "$SOURCE_POD")" || die "could not fingerprint $SOURCE_POD"
sed 's/^/  before: /' <<<"$FP_BEFORE"
"$LIB_DIR/backup_now.sh" "$ENGINE" "$ENV" | sed 's/^/  | /'
[[ "${PIPESTATUS[0]}" -eq 0 ]] || die "the backup failed"
FP_AFTER="$(fingerprint "$SOURCE_POD")" || die "could not fingerprint $SOURCE_POD"
sed 's/^/  after:  /' <<<"$FP_AFTER"
[[ "$FP_BEFORE" == "$FP_AFTER" ]] || die "the source changed during the backup (something is writing): rerun when idle"
if [[ "$ENGINE" == pg ]]; then
  BACKUP="$(k -n "$NS" get backups.postgresql.cnpg.io --sort-by=.metadata.creationTimestamp \
    -o jsonpath='{range .items[?(@.status.phase=="completed")]}{.metadata.name}{"\n"}{end}' | tail -1)"
else
  BACKUP="$(k -n "$NS" get perconaxtradbclusterbackups.pxc.percona.com --sort-by=.metadata.creationTimestamp \
    -o jsonpath='{range .items[?(@.status.state=="Succeeded")]}{.metadata.name}{"\n"}{end}' | tail -1)"
  DEST="$(k -n "$NS" get perconaxtradbclusterbackups.pxc.percona.com "$BACKUP" -o jsonpath='{.status.destination}')"
fi
echo "  backup to restore: $BACKUP${DEST:+ ($DEST)}"

# --- 2. restore ---
step "2. Restore into $TARGET (one instance)"
T0=$SECONDS
if [[ "$ENGINE" == pg ]]; then
  # Same image, resources and size as the source; the newest base backup in
  # the store (the one just taken), then every archived WAL file. No
  # plugins section: the restored cluster must not archive into the
  # source's path.
  k -n "$NS" get clusters.postgresql.cnpg.io pg -o json | jq --arg name "$TARGET" '{
    apiVersion, kind,
    metadata: {name: $name, namespace: .metadata.namespace, labels: {"app.kubernetes.io/part-of": "runbook-8"}},
    spec: {
      instances: 1,
      imageName: .spec.imageName,
      resources: .spec.resources,
      storage: {size: .spec.storage.size},
      enableSuperuserAccess: false,
      bootstrap: {recovery: {source: "origin", database: "appdb", owner: "app"}},
      externalClusters: [{name: "origin", plugin: {
        name: "barman-cloud.cloudnative-pg.io",
        parameters: {barmanObjectName: "pg-backups", serverName: "pg"}}}]
    }}' | k apply -f - || die "could not create $TARGET"
  restored() { [[ "$(k -n "$NS" get clusters.postgresql.cnpg.io "$TARGET" -o jsonpath='{.status.phase} {.status.readyInstances}')" == "Cluster in healthy state 1" ]]; }
  wait_for "$LIMIT" restored || die "$TARGET not healthy after ${LIMIT}s: $(k -n "$NS" get clusters.postgresql.cnpg.io "$TARGET" -o jsonpath='{.status.phase}')"
  TARGET_POD="$TARGET-1"
else
  # The backup's mysql.user holds the live cluster's system passwords, so the
  # restored cluster must use the same ones: copy the Secret (never printed).
  k -n "$NS" get secret mysql-secrets -o json | jq --arg name "$TARGET-secrets" '{
    apiVersion, kind, type, data,
    metadata: {name: $name, namespace: .metadata.namespace, labels: {"app.kubernetes.io/part-of": "runbook-8"}}}' |
    k apply -f - >/dev/null || die "could not copy the system passwords"
  # Same images, resources, configuration and storage as the source; one
  # node and one HAProxy (unsafeFlags: Percona wants 3); the backup storage
  # without a schedule or binlog collector, so it never writes to the store.
  k -n "$NS" get perconaxtradbclusters.pxc.percona.com mysql -o json | jq --arg name "$TARGET" '{
    apiVersion, kind,
    metadata: {name: $name, namespace: .metadata.namespace, labels: {"app.kubernetes.io/part-of": "runbook-8"},
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
    }}' | k apply -f - || die "could not create $TARGET"
  created() { [[ "$(k -n "$NS" get perconaxtradbclusters.pxc.percona.com "$TARGET" -o jsonpath='{.status.state} {.status.pxc.ready}')" == "ready 1" ]]; }
  printf '  empty cluster ready'
  wait_for 900 created || die "$TARGET not ready after 900 s"
  RESTORE="$TARGET-$(date -u +%Y%m%d-%H%M%S)"
  # The store's S3 settings inline, from the live cluster's storage: with only
  # storageName, operator 1.20 fails "nil s3 backup status storage"
  # (2026-11-03), though the CRD accepts it.
  k -n "$NS" get perconaxtradbclusters.pxc.percona.com mysql -o json | jq --arg name "$RESTORE" --arg target "$TARGET" --arg dest "$DEST" '{
    apiVersion, kind: "PerconaXtraDBClusterRestore",
    metadata: {name: $name, namespace: .metadata.namespace, labels: {"app.kubernetes.io/part-of": "runbook-8"}},
    spec: {pxcCluster: $target, backupSource: {destination: $dest, s3: .spec.backup.storages.s3.s3}}}' |
    k apply -f - || die "could not create the restore"
  restore_done() {
    local s
    s="$(k -n "$NS" get perconaxtradbclusterrestores.pxc.percona.com "$RESTORE" -o jsonpath='{.status.state}')"
    [[ "$s" != "$LAST" ]] && echo "  $(date -u +%H:%M:%S) ${s:-(no status yet)}" >&2 && LAST="$s"
    [[ "$s" == Failed || "$s" == Error ]] && return 2
    [[ "$s" == Succeeded ]]
  }
  LAST=""
  until restore_done; do
    [[ $? -eq 2 ]] && die "the restore failed: $(k -n "$NS" get perconaxtradbclusterrestores.pxc.percona.com "$RESTORE" -o jsonpath='{.status.comments}')"
    ((SECONDS - T0 >= LIMIT)) && die "the restore did not finish in ${LIMIT}s"
    sleep 10
  done
  printf '  restored cluster ready'
  wait_for 600 created || die "$TARGET not ready after the restore"
  TARGET_POD="$TARGET-pxc-0"
fi
RTO=$((SECONDS - T0))
echo "  Restore time (create to ready, the RTO for this size): $RTO s"

# --- 3. consistency ---
step "3. Consistency checks on $TARGET_POD"
if [[ "$ENGINE" == pg ]]; then
  N="$(pg_sql "$TARGET_POD" "CREATE EXTENSION IF NOT EXISTS amcheck;
    SELECT sum(CASE WHEN bt_index_check(c.oid, true) IS NULL THEN 1 ELSE 1 END) FROM pg_index i
      JOIN pg_class c ON c.oid = i.indexrelid JOIN pg_am a ON a.oid = c.relam
      WHERE a.amname = 'btree' AND c.relnamespace = 'public'::regnamespace")" || die "amcheck found a problem"
  echo "  amcheck: $N B-tree indexes checked against their tables, no errors"
  ((N > 0)) || die "amcheck checked no indexes"
else
  OUT="$(my_sql "$TARGET_POD" "CHECK TABLE appdb.customers, appdb.orders")" || die "CHECK TABLE failed to run"
  sed 's/^/  /' <<<"$OUT"
  [[ "$(awk -F'\t' '$3 == "status" && $4 == "OK"' <<<"$OUT" | wc -l | tr -d ' ')" == 2 ]] || die "CHECK TABLE did not report OK for both tables"
fi

# --- 4. the data ---
step "4. The restored data equals the source's"
FP_RESTORED="$(fingerprint "$TARGET_POD")" || die "could not fingerprint $TARGET_POD"
sed 's/^/  restored: /' <<<"$FP_RESTORED"
[[ "$FP_RESTORED" == "$FP_BEFORE" ]] || die "the restored data differs from the source"
echo "  match: $(awk '{n += $2} END {print n}' <<<"$FP_RESTORED") rows"

# --- 5. application queries ---
step "5. Application queries as app, over TLS, through $TARGET's endpoint"
Q_READ="SELECT count(*) FROM orders WHERE customer_id = (SELECT min(id) FROM customers)"
if [[ "$ENGINE" == pg ]]; then
  APP_PW="$(k -n "$NS" get secret "$TARGET-app" -o jsonpath='{.data.password}' | base64 -d)"
  OUT="$(k -n "$NS" exec -i "$TARGET_POD" -c postgres -- sh -c \
    'read -r PGPASSWORD; export PGPASSWORD; exec psql -XAtq -v ON_ERROR_STOP=1 "host=$0 user=app dbname=appdb sslmode=require connect_timeout=5" -c "$1" -c BEGIN -c "$2" -c ROLLBACK' \
    "$TARGET-rw" "$Q_READ" "INSERT INTO customers (name, email) VALUES ('runbook 8', 'r8@example.com') RETURNING 'write ok'" <<<"$APP_PW")" ||
    die "an application query failed: $OUT"
else
  APP_PW="$(k -n "$NS" get secret mysql-custom-user-secret -o jsonpath='{.data.app}' | base64 -d)"
  OUT="$(k -n "$NS" exec -i "$TARGET_POD" -c pxc -- sh -c \
    'read -r MYSQL_PWD; export MYSQL_PWD; exec mysql -uapp -h "$0" --ssl-mode=REQUIRED --connect-timeout=5 -D appdb -NBe "$1; $2"' \
    "$TARGET-haproxy" "$Q_READ" "BEGIN; INSERT INTO customers (name, email) VALUES ('runbook 8', 'r8@example.com'); SELECT 'write ok'; ROLLBACK" <<<"$APP_PW")" ||
    die "an application query failed: $OUT"
fi
sed 's/^/  /' <<<"$OUT"
[[ "$OUT" == *"write ok"* ]] || die "the write did not succeed"

# --- 6. clean up ---
if [[ -n "$KEEP" ]]; then
  step "6. Kept $TARGET (--keep); delete it when done:"
  if [[ "$ENGINE" == pg ]]; then echo "  kubectl -n $NS delete clusters.postgresql.cnpg.io $TARGET"
  else echo "  kubectl -n $NS delete pxc $TARGET && kubectl -n $NS delete secret $TARGET-secrets"; fi
else
  step "6. Delete $TARGET"
  if [[ "$ENGINE" == pg ]]; then
    k -n "$NS" delete clusters.postgresql.cnpg.io "$TARGET" --wait=true --timeout=300s >/dev/null || die "could not delete $TARGET"
  else
    k -n "$NS" delete perconaxtradbclusterrestores.pxc.percona.com "$RESTORE" >/dev/null
    k -n "$NS" delete perconaxtradbclusters.pxc.percona.com "$TARGET" --wait=true --timeout=300s >/dev/null || die "could not delete $TARGET"
    k -n "$NS" delete secret "$TARGET-secrets" "internal-$TARGET" --ignore-not-found >/dev/null
  fi
  gone() { [[ -z "$(k -n "$NS" get pods,pvc -o name | grep -- "$TARGET")" ]]; }
  wait_for 300 gone || die "pods or volumes of $TARGET are still there"
  LEFT="$(k -n "$NS" get secrets,certificates.cert-manager.io,issuers.cert-manager.io -o name 2>/dev/null | grep -- "$TARGET" | xargs)"
  [[ -z "$LEFT" ]] && echo "  nothing of $TARGET left" || echo "  left over (harmless, delete by hand): $LEFT"
fi

# --- 7. verify ---
verify_check
echo
echo "PASS: $BACKUP restored into $TARGET in $RTO s; data identical ($(awk '{n += $2} END {print n}' <<<"$FP_RESTORED") rows), consistent, usable by the app."
