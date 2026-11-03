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
NEED_MIB=3072 # free VM memory needed: the restored database plus its restore job
source "$(dirname "$0")/runbook_lib.sh" # restore_*: the temporary cluster
runbook_start 8 "${ARGS[@]}"

# --- 0. preconditions ---
step "0. Preconditions"
whole || die "the $ENGINE cluster is not whole (run check_resources.sh)"
restore_absent "$TARGET"
if [[ "$ENGINE" == pg ]]; then
  SOURCE_POD="$(pg_primary)"
else
  SOURCE_POD="$(my_nonwriter)" || die "could not ask HAProxy which node is the writer"
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
if [[ "$ENGINE" == pg ]]; then restore_pg "$TARGET"; else restore_my "$TARGET" "$DEST"; fi
RTO=$((SECONDS - T0))
echo "  Restore time (create to ready, the RTO for this size): $RTO s"

# --- 3. consistency ---
step "3. Consistency checks on $TARGET_POD"
restore_consistent "$TARGET_POD"

# --- 4. the data ---
step "4. The restored data equals the source's"
FP_RESTORED="$(fingerprint "$TARGET_POD")" || die "could not fingerprint $TARGET_POD"
sed 's/^/  restored: /' <<<"$FP_RESTORED"
[[ "$FP_RESTORED" == "$FP_BEFORE" ]] || die "the restored data differs from the source"
echo "  match: $(awk '{n += $2} END {print n}' <<<"$FP_RESTORED") rows"

# --- 5. application queries ---
step "5. Application queries as app, over TLS, through $TARGET's endpoint"
restore_app_queries "$TARGET" "$TARGET_POD"

# --- 6. clean up ---
if [[ -n "$KEEP" ]]; then
  step "6. Kept $TARGET (--keep); delete it when done:"
  restore_hint "$TARGET"
else
  step "6. Delete $TARGET"
  restore_delete "$TARGET"
fi

# --- 7. verify ---
verify_check
echo
echo "PASS: $BACKUP restored into $TARGET in $RTO s; data identical ($(awk '{n += $2} END {print n}' <<<"$FP_RESTORED") rows), consistent, usable by the app."
