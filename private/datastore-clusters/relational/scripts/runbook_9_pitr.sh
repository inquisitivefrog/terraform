#!/usr/bin/env bash
# Runbook 9, point-in-time recovery: a bad DELETE on the live cluster,
# recovered by restoring to just before it into a new cluster and copying
# the lost rows back.
#   0. preconditions: the cluster is whole; a full backup in the store (the
#      recovery starts from it); no recovery cluster left over; free memory;
#      no other load running
#   1. a k6 run writes orders (default 20 requests/s for 3m), after the
#      backup: they exist only in the archived WAL / binlogs, so the
#      recovery has to replay them
#   2. the good state: once the load ends, fingerprint the source (per
#      table: rows, highest id, a checksum of every row) twice, 5 s apart:
#      equal, so it is idle; count the run's orders
#   3. the mistake: note the server's time T, then DELETE every order the
#      run wrote (run_id), on the writer
#   4. the logs past T are in the store: pg switches to a new WAL file and
#      waits until it is archived; mysql waits until an uploaded binlog's
#      GTID set covers the last transaction before T
#   5. recover to T into <engine>-recovered, one instance:
#        pg     bootstrap.recovery with recoveryTarget.targetTime T
#               (microseconds): the newest base backup before T, then WAL
#               up to T
#        mysql  a PerconaXtraDBClusterRestore of the newest full backup
#               with pitr type date T (whole seconds: T is the next second
#               after the good state, the DELETE 3 s later)
#      prints how long until it is ready (the RTO for this size)
#   6. it is consistent (amcheck / CHECK TABLE) and its fingerprint equals
#      the good state's: the deleted rows are there, the DELETE is not
#   7. copy the run's orders from <engine>-recovered back into the live cluster;
#      the live fingerprint equals the good state's again
#   8. delete <engine>-recovered (kept with --keep, or when a step fails)
#   9. verify: relational check_resources.sh passes
# Here T is known because the script made the mistake. For a real one, find
# it in the logs: the app's, the database's (pg log_min_duration_statement,
# mysql general log if on), or the WAL / binlog themselves (pg_waldump,
# mysqlbinlog).
# Usage: private/datastore-clusters/relational/scripts/runbook_9_pitr.sh pg|mysql [--keep] [rate] [duration] [dev]
# Log: relational/logs/runbook-9-<engine>-<time>.txt (-FAILED.txt if it fails)

ENGINE="${1:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ ]] || {
  echo "Usage: $0 pg|mysql [--keep] [rate] [duration] [dev]" >&2
  exit 1
}
ARGS=("$@")
shift
KEEP=""
[[ "${1:-}" == --keep ]] && KEEP=1 && shift
RATE="${1:-20}"
DURATION="${2:-3m}"
ENV="${3:-dev}"
TARGET="$ENGINE-recovered" # not -pitr: the live binlog collector is mysql-pitr
NEED_MIB=3072 # free VM memory needed: the recovered database plus its restore job
source "$(dirname "$0")/runbook_lib.sh" # load_*, restore_*
runbook_start 9 "${ARGS[@]}"
KEYS="$HOME/.config/datastore-dev/backup-store/s3.json"

# my_binlogs_cover <gtid set>: an uploaded binlog's GTID set (the
# binlog_*-gtid-set objects the collector writes beside each binlog) holds
# the last transaction of every source in the set (keys handed to curl on
# stdin, never printed)
my_binlogs_cover() {
  python3 - "$KEYS" "$1" <<'EOF'
import json, os, re, subprocess, sys
keys, want = sys.argv[1:]
c = next(i for i in json.load(open(keys))["identities"] if i["name"] == "mysql")["credentials"][0]
def get(path):
    return subprocess.run(["curl", "-s", "--aws-sigv4", "aws:amz:us-east-1:s3", "-K", "-", f"https://localhost:8333/mysql-backups{path}"],
                          input=f'user = "{c["accessKey"]}:{c["secretKey"]}"\ncacert = "{os.path.dirname(keys)}/ca.crt"', capture_output=True, text=True).stdout
def last(gtids):  # {uuid: highest transaction number}
    out = {}
    for part in gtids.replace("\n", "").split(","):
        uuid, *ranges = part.strip().split(":")
        out[uuid] = max(int(r.split("-")[-1]) for r in ranges)
    return out
names, token = [], ""
while True:
    page = get("?list-type=2&prefix=binlog_" + (f"&continuation-token={token}" if token else ""))
    names += re.findall(r"<Key>([^<]+-gtid-set)</Key>", page)
    m = re.search(r"<NextContinuationToken>([^<]+)</NextContinuationToken>", page)
    if "<IsTruncated>true</IsTruncated>" not in page or not m:
        break
    token = m.group(1)
names.sort(key=lambda n: int(n.split("_")[1]))  # binlog_<epoch>_<n>_<hash>-gtid-set
need = last(want)
for name in names[-30:]:
    for uuid, ranges in [(p.split(":")[0], p.split(":")[1:]) for p in get("/" + name).strip().split(",") if p]:
        for r in ranges:
            a, b = (r.split("-") + [r])[:2]
            if uuid in need and int(a) <= need[uuid] <= int(b):
                need.pop(uuid)
sys.exit(0 if not need else 1)
EOF
}

# --- 0. preconditions ---
step "0. Preconditions"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
restore_absent "$TARGET"
[[ -n "$(k -n "$NS" get pods -l "$APP_PODS" -o name)" ]] || die "no orders-$ENGINE pods: apply the app root first"
[[ -z "$(k -n "$NS" get jobs -l app.kubernetes.io/name=k6 -o jsonpath='{.items[?(@.status.active)].metadata.name}' 2>/dev/null)" ]] ||
  die "another k6 load is running: the source must be idle after this run's load"
if [[ "$ENGINE" == pg ]]; then
  BACKUP="$(k -n "$NS" get backups.postgresql.cnpg.io --sort-by=.metadata.creationTimestamp \
    -o jsonpath='{range .items[?(@.status.phase=="completed")]}{.metadata.name}{"\n"}{end}' | tail -1)"
  [[ -n "$BACKUP" ]] || die "no completed base backup: run backup_now.sh pg"
  SOURCE_POD="$(pg_primary)"
  WRITER="$SOURCE_POD"
else
  BACKUP="$(k -n "$NS" get perconaxtradbclusterbackups.pxc.percona.com --sort-by=.metadata.creationTimestamp \
    -o jsonpath='{range .items[?(@.status.state=="Succeeded")]}{.metadata.name}{"\n"}{end}' | tail -1)"
  [[ -n "$BACKUP" ]] || die "no succeeded full backup: run backup_now.sh mysql"
  DEST="$(k -n "$NS" get perconaxtradbclusterbackups.pxc.percona.com "$BACKUP" -o jsonpath='{.status.destination}')"
  [[ "$(k -n "$NS" get deploy mysql-pitr -o jsonpath='{.status.readyReplicas}')" == 1 ]] || die "the binlog collector mysql-pitr is not ready"
  WRITER="$(my_writer)" || die "could not ask HAProxy which node is the writer"
  SOURCE_POD="$(my_nonwriter)"
fi
FREE="$(vm_free_mib)"
echo "  backup to start from: $BACKUP${DEST:+ ($DEST)}"
echo "  writer: $WRITER; fingerprints from: $SOURCE_POD; Docker VM memory free: $FREE MiB (need $NEED_MIB)"
((FREE >= NEED_MIB)) || die "not enough free memory for a fifth database: stop something first"

# --- 1. writes after the backup ---
load_start "$RATE" "$DURATION"
load_finish "not judged here: this run is about the recovery"
RUN="$TESTID"
[[ "$RUN" =~ ^[a-z]+-[a-z]+-[0-9-]+$ ]] || die "unexpected run id '$RUN'"

# --- 2. the good state ---
step "2. The good state (idle)"
sleep 5
FP_GOOD="$(fingerprint "$SOURCE_POD")" || die "could not fingerprint $SOURCE_POD"
sleep 5
[[ "$(fingerprint "$SOURCE_POD")" == "$FP_GOOD" ]] || die "the source is still changing: something else is writing"
sed 's/^/  good: /' <<<"$FP_GOOD"
if [[ "$ENGINE" == pg ]]; then
  N_RUN="$(pg_sql "$SOURCE_POD" "SELECT count(*) FROM orders WHERE run_id = '$RUN'")"
else
  N_RUN="$(my_sql "$SOURCE_POD" "SELECT COUNT(*) FROM appdb.orders WHERE run_id = '$RUN'")"
fi
echo "  orders written by run $RUN (left after its own deletes): $N_RUN"
((N_RUN > 0)) || die "the run left no orders to delete"

# --- 3. the mistake ---
step "3. The mistake: DELETE the run's orders on $WRITER"
if [[ "$ENGINE" == pg ]]; then
  T="$(pg_sql "$WRITER" "SELECT to_char(clock_timestamp() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI:SS.US') || '+00'")"
  sleep 2
  DELETED="$(pg_sql "$WRITER" "WITH d AS (DELETE FROM orders WHERE run_id = '$RUN' RETURNING 1) SELECT count(*) FROM d")"
else
  GTID_T="$(my_sql "$WRITER" "SELECT @@GLOBAL.gtid_executed" | tr -d '\n')"
  T="$(my_sql "$WRITER" "SELECT DATE_FORMAT(UTC_TIMESTAMP() + INTERVAL 1 SECOND, '%Y-%m-%d %H:%i:%s')")"
  sleep 3
  DELETED="$(my_sql "$WRITER" "DELETE FROM appdb.orders WHERE run_id = '$RUN'; SELECT ROW_COUNT()")"
fi
echo "  T (recover to): $T UTC${GTID_T:+; GTIDs executed by then: $GTID_T}"
echo "  deleted: $DELETED rows"
[[ "$DELETED" == "$N_RUN" ]] || die "deleted $DELETED rows, expected $N_RUN"
sleep 2
FP_BAD="$(fingerprint "$SOURCE_POD")"
sed 's/^/  now:  /' <<<"$FP_BAD"
[[ "$FP_BAD" != "$FP_GOOD" ]] || die "the DELETE changed nothing"

# --- 4. the logs past T in the store ---
step "4. The logs past T are in the store"
if [[ "$ENGINE" == pg ]]; then
  WAL="$(pg_sql "$WRITER" "SELECT pg_walfile_name(pg_switch_wal())")"
  echo "  switched WAL; waiting for $WAL to be archived"
  _archived() { [[ "$(pg_sql "$WRITER" "SELECT last_archived_wal >= '$WAL' FROM pg_stat_archiver")" == t ]]; }
  wait_for 600 _archived || die "$WAL not archived after 600 s"
else
  echo "  waiting for an uploaded binlog to cover $GTID_T (the collector uploads every 60 s)"
  wait_for 600 my_binlogs_cover "$GTID_T" || die "the binlogs up to T are not in the store after 600 s"
fi

# --- 5. recover to T ---
step "5. Recover to $T into $TARGET (one instance)"
T0=$SECONDS
if [[ "$ENGINE" == pg ]]; then restore_pg "$TARGET" "$T"; else restore_my "$TARGET" "$DEST" "$T"; fi
RTO=$((SECONDS - T0))
echo "  Recovery time (create to ready, the RTO for this size): $RTO s"

# --- 6. the recovered data ---
step "6. $TARGET is consistent and holds the good state"
restore_consistent "$TARGET_POD"
FP_PITR="$(fingerprint "$TARGET_POD")" || die "could not fingerprint $TARGET_POD"
sed 's/^/  recovered: /' <<<"$FP_PITR"
[[ "$FP_PITR" == "$FP_GOOD" ]] || die "the recovered data is not the good state"
echo "  match: the $N_RUN deleted orders are there, the DELETE is not"

# --- 7. copy the lost rows back ---
step "7. Copy the run's orders from $TARGET back into the live cluster"
if [[ "$ENGINE" == pg ]]; then
  # Through a temporary table: the ids are identity columns (GENERATED
  # ALWAYS), so they go back with OVERRIDING SYSTEM VALUE.
  COPIED="$(k -n "$NS" exec "$TARGET_POD" -c postgres -- psql -XAtq -v ON_ERROR_STOP=1 -d appdb \
    -c "\copy (SELECT * FROM orders WHERE run_id = '$RUN') TO STDOUT" |
    k -n "$NS" exec -i "$WRITER" -c postgres -- psql -XAtq -v ON_ERROR_STOP=1 -d appdb \
      -c "CREATE TEMP TABLE lost (LIKE orders)" -c "\copy lost FROM pstdin" \
      -c "WITH ins AS (INSERT INTO orders OVERRIDING SYSTEM VALUE SELECT * FROM lost RETURNING 1) SELECT count(*) FROM ins")" ||
    die "the copy failed"
else
  # mysqldump of just those rows (with their ids), into the writer. Each
  # side reads root's password from its first line of input.
  { printf '%s\n' "$MY_ROOT_PW"
    k -n "$NS" exec -i "$TARGET_POD" -c pxc -- sh -c \
      'read -r MYSQL_PWD; export MYSQL_PWD; exec mysqldump -uroot --no-create-info --compact --skip-add-locks --skip-lock-tables --single-transaction --set-gtid-purged=OFF --where="$0" appdb orders' \
      "run_id = '$RUN'" <<<"$MY_ROOT_PW"; } |
    k -n "$NS" exec -i "$WRITER" -c pxc -- sh -c 'read -r MYSQL_PWD; export MYSQL_PWD; exec mysql -uroot -D appdb' ||
    die "the copy failed"
  sleep 2
  COPIED="$(my_sql "$WRITER" "SELECT COUNT(*) FROM appdb.orders WHERE run_id = '$RUN'")"
fi
echo "  copied back: $COPIED rows"
[[ "$COPIED" == "$N_RUN" ]] || die "copied $COPIED rows, expected $N_RUN"
sleep 2
FP_LIVE="$(fingerprint "$SOURCE_POD")"
sed 's/^/  live: /' <<<"$FP_LIVE"
[[ "$FP_LIVE" == "$FP_GOOD" ]] || die "the live cluster does not match the good state after the copy"
echo "  the live cluster is back to the good state"

# --- 8. clean up ---
if [[ -n "$KEEP" ]]; then
  step "8. Kept $TARGET (--keep); delete it when done:"
  restore_hint "$TARGET"
else
  step "8. Delete $TARGET"
  restore_delete "$TARGET"
fi

# --- 9. verify ---
verify_check
echo
echo "PASS: recovered to $T in $RTO s from $BACKUP plus the logs; $N_RUN deleted orders recovered and copied back; the live cluster is back to the good state."
