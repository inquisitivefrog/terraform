#!/usr/bin/env bash
# Runbook 12, backup and archive storage check: the backup store is healthy,
# has space, keeps what retention promises, and the logs a restore needs are
# all there. Read-only: lists the buckets and asks the clusters; changes
# nothing. Weekly, and before relying on a backup.
#   the store       running; its data and the Mac's free disk (the Docker VM's
#                   disk image grows into it), growth since the last run;
#                   immutability (versioning / object lock)
#   PostgreSQL      archiving current (pg_stat_archiver); every base backup in
#                   the store complete; retention (none older than the 7-day
#                   window plus a weekly cycle); WAL continuous from the oldest
#                   base backup's first segment to the last archived one
#   MySQL           the binlog collector up, not restarting, memory under its
#                   limit; uploaded binlogs continuous (one GTID interval) and
#                   current (cover what the cluster executed); no gap marker
#                   (pitr-not-ready); every succeeded backup's files in the
#                   store, none orphaned; scheduled backups within "keep"
# PASS / FAIL per check, WARN for known gaps that need no action today.
# Usage: private/datastore-clusters/relational/scripts/runbook_12_store.sh [dev]
# Log: relational/logs/runbook-12-<time>.txt (-FAILED.txt if a check fails)

ENV="${1:-dev}"
ENGINE=mysql # for my_sql and the restore helpers' engine switch; this runbook covers both
source "$(dirname "$0")/runbook_lib.sh" # my_sql, wait_for; checks.sh: pass, fail, summary
KEYS="$HOME/.config/datastore-dev/backup-store/s3.json"
STORE=datastore-backups
PG_WINDOW_DAYS=7  # the ObjectStore's retentionPolicy (7d)
PG_CYCLE_DAYS=7   # base backups weekly: the oldest kept may be one cycle older
MY_KEEP=2         # scheduled full backups kept (clusters root, keep)
MIN_FREE_GIB=10   # the Mac's free disk below this fails

use_cluster "datastore-$ENV"
PREV_LOG="$(ls -t "$LIB_DIR/../logs"/runbook-12-[0-9]*.txt 2>/dev/null | grep -v FAILED | head -1)"
runbook_log "$LIB_DIR/../logs" "runbook-12" "$@"
MY_ROOT_PW="$(k -n "$NS" get secret mysql-secrets -o jsonpath='{.data.root}' | base64 -d)"
WARN=0
warn() { echo "  WARN  $1: $2"; WARN=$((WARN + 1)); }

# s3 <identity> <path>: a GET against the store with that identity's key
# (handed to curl on stdin, never printed)
s3() {
  python3 - "$KEYS" "$@" <<'EOF'
import json, subprocess, sys
keys, identity, path = sys.argv[1:]
c = next(i for i in json.load(open(keys))["identities"] if i["name"] == identity)["credentials"][0]
r = subprocess.run(["curl", "-s", "--aws-sigv4", "aws:amz:us-east-1:s3", "-K", "-", f"http://localhost:8333/{path}"],
                   input=f'user = "{c["accessKey"]}:{c["secretKey"]}"', capture_output=True, text=True)
sys.stdout.write(r.stdout)
EOF
}
# inventory <identity> <bucket>: every object, "key<TAB>size<TAB>modified"
inventory() {
  python3 - "$KEYS" "$@" <<'EOF'
import json, re, subprocess, sys, urllib.parse
keys, identity, bucket = sys.argv[1:]
c = next(i for i in json.load(open(keys))["identities"] if i["name"] == identity)["credentials"][0]
token = ""
while True:
    q = "list-type=2" + (("&continuation-token=" + urllib.parse.quote(token)) if token else "")
    page = subprocess.run(["curl", "-s", "--aws-sigv4", "aws:amz:us-east-1:s3", "-K", "-", f"http://localhost:8333/{bucket}?{q}"],
                          input=f'user = "{c["accessKey"]}:{c["secretKey"]}"', capture_output=True, text=True).stdout
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

echo "== Runbook 12: backup and archive storage ($(date -u +%Y-%m-%dT%H:%M:%SZ)) =="

# --- the store ---
echo; echo "-- the store ($STORE) --"
if [[ "$(docker inspect -f '{{.State.Running}}' "$STORE" 2>/dev/null)" == true ]]; then pass "Running" "true"; else fail "Running" "not running"; fi
STORE_KIB="$(docker exec "$STORE" du -sk /data 2>/dev/null | awk '{print $1}')"
MAC_FREE_KIB="$(df -k /System/Volumes/Data | awk 'NR == 2 {print $4}')"
echo "  store total: $((STORE_KIB / 1024)) MiB on disk; the Mac's free disk: $((MAC_FREE_KIB / 1048576)) GiB"
if [[ -n "$PREV_LOG" ]]; then
  PREV="$(grep -m1 -oE 'store total: [0-9]+ MiB' "$PREV_LOG" | grep -oE '[0-9]+')"
  [[ -n "$PREV" ]] && echo "  growth since $(basename "$PREV_LOG" .txt | sed 's/runbook-12-//'): $((STORE_KIB / 1024 - PREV)) MiB"
fi
NEED_KIB=$((MIN_FREE_GIB * 1048576))
((2 * STORE_KIB > NEED_KIB)) && NEED_KIB=$((2 * STORE_KIB))
if ((MAC_FREE_KIB >= NEED_KIB)); then
  pass "Free disk for the store to grow (at least ${MIN_FREE_GIB} GiB and twice its size)" "$((MAC_FREE_KIB / 1048576)) GiB free"
else
  fail "Free disk for the store to grow (at least ${MIN_FREE_GIB} GiB and twice its size)" "$((MAC_FREE_KIB / 1048576)) GiB free, store $((STORE_KIB / 1024)) MiB"
fi
for e in pg mysql; do
  read -r n b < <(inventory "$e" "$e-backups" | awk -F'\t' '{n++; s += $2} END {print n + 0, s + 0}')
  echo "  bucket $e-backups: $n objects, $(mib "$b")"
  v="$(s3 "$e" "$e-backups?versioning" | grep -oE '<Status>[A-Za-z]+</Status>' | sed 's/<[^>]*>//g')"
  if [[ "$v" == Enabled ]]; then pass "$e-backups versioning (needed for object lock)" "$v"; else
    warn "$e-backups immutable copy" "versioning ${v:-off}, so no object lock: a stolen key can delete backups (known gap, runbook 7)"; fi
done

# --- PostgreSQL ---
echo; echo "-- PostgreSQL (s3://pg-backups/pg/) --"
PG_PRIMARY="$(pg_primary)"
# Current: every segment before the one being written is archived. Not "archived
# in the last few minutes": an idle database switches no segment for hours.
read -r ARCH_WAL CUR_WAL ARCH_AGE FAIL_AFTER <<<"$(pg_sql "$PG_PRIMARY" "SELECT last_archived_wal,
  pg_walfile_name(pg_current_wal_lsn()), extract(epoch FROM now() - last_archived_time)::int,
  (last_failed_time IS NOT NULL AND last_failed_time > last_archived_time) FROM pg_stat_archiver")"
BEHIND="$(python3 -c 'import sys; n = lambda w: int(w[8:16], 16) * 256 + int(w[16:24], 16); print(n(sys.argv[2]) - n(sys.argv[1]) - 1)' "$ARCH_WAL" "$CUR_WAL")"
if [[ "$BEHIND" -le 0 && "$FAIL_AFTER" == f ]]; then
  pass "Archiving current (every segment before the one being written, no failure since)" "$ARCH_WAL archived $ARCH_AGE s ago, writing $CUR_WAL"
else
  fail "Archiving current (every segment before the one being written, no failure since)" "$BEHIND segments waiting, last $ARCH_WAL, writing $CUR_WAL, failing since: $FAIL_AFTER"
fi
PG_INV="$(inventory pg pg-backups)" || fail "pg-backups listing" "failed"
# Base backups: a complete one has data.tar* and a backup.info with status DONE
BASES=""
for id in $(awk -F'\t' '$1 ~ /^pg\/base\/[^\/]+\/backup.info$/ {split($1, p, "/"); print p[3]}' <<<"$PG_INV" | sort); do
  info="$(s3 pg "pg-backups/pg/base/$id/backup.info")"
  status="$(sed -n 's/^status=//p' <<<"$info")"
  begin="$(sed -n 's/^begin_wal=//p' <<<"$info")"
  size="$(awk -F'\t' -v p="pg/base/$id/data" 'index($1, p) == 1 {s += $2} END {print s + 0}' <<<"$PG_INV")"
  if [[ "$status" == DONE && "$size" -gt 0 ]]; then
    echo "  base backup $id: done, $(mib "$size"), first WAL $begin"
    BASES+="$id $begin"$'\n'
  else
    warn "Base backup $id" "status ${status:-unknown}, $(mib "$size") of data: an incomplete or failed backup's leftovers (delete by hand, or retention will)"
  fi
done
OLDEST_ID="$(head -1 <<<"$BASES" | awk '{print $1}')"
OLDEST_WAL="$(head -1 <<<"$BASES" | awk '{print $2}')"
if [[ -z "$OLDEST_ID" ]]; then
  fail "A complete base backup in the store" "none"
else
  pass "A complete base backup in the store" "$(grep -c . <<<"$BASES") (newest $(grep . <<<"$BASES" | tail -1 | awk '{print $1}'))"
  AGE_D="$(python3 -c "import datetime as d, sys; t = d.datetime.strptime(sys.argv[1], '%Y%m%dT%H%M%S'); print((d.datetime.now(d.UTC).replace(tzinfo=None) - t).days)" "$OLDEST_ID")"
  if ((AGE_D <= PG_WINDOW_DAYS + PG_CYCLE_DAYS)); then
    pass "Retention: oldest base backup within ${PG_WINDOW_DAYS} days plus a ${PG_CYCLE_DAYS}-day cycle" "$OLDEST_ID, $AGE_D days"
  else
    fail "Retention: oldest base backup within ${PG_WINDOW_DAYS} days plus a ${PG_CYCLE_DAYS}-day cycle" "$OLDEST_ID, $AGE_D days: retention is not deleting"
  fi
  # WAL: every segment from the oldest base backup's first one to the last
  # archived, on any timeline (a switchover continues the same segment
  # numbers on the next timeline). Older WAL is never used by a restore.
  RESULT="$(awk -F'\t' '{print $1}' <<<"$PG_INV" | python3 -c '
import re, sys
first, last = sys.argv[1], sys.argv[2]
num = lambda w: int(w[8:16], 16) * 256 + int(w[16:24], 16)
segs, older = set(), 0
for k in sys.stdin:
    m = re.search(r"/([0-9A-F]{24})(\.partial)?\.", k)
    if m:
        n = num(m.group(1))
        segs.add(n)
        older += n < num(first)
want = range(num(first), num(last) + 1)
missing = [n for n in want if n not in segs]
print(len(want), len(missing), older, " ".join("%08X%08X" % divmod(n, 256) for n in missing[:5]))' "$OLDEST_WAL" "$ARCH_WAL")"
  read -r WANT MISSING OLDER FIRST_MISSING <<<"$RESULT"
  if [[ "$MISSING" == 0 ]]; then
    pass "WAL continuous from the oldest base backup ($OLDEST_WAL) to the last archived ($ARCH_WAL)" "$WANT segments, none missing"
  else
    fail "WAL continuous from the oldest base backup ($OLDEST_WAL) to the last archived ($ARCH_WAL)" "$MISSING of $WANT missing (first: $FIRST_MISSING)"
  fi
  ((OLDER > 0)) && warn "WAL older than the oldest base backup" "$OLDER files numbered before it: no restore from these backups uses them"
fi
FIRST_RP="$(k -n "$NS" get objectstores.barmancloud.cnpg.io pg-backups -o jsonpath='{.status.serverRecoveryWindow.pg.firstRecoverabilityPoint}')"
echo "  restorable from (the plugin's first recoverability point): ${FIRST_RP:-unknown}"

# --- MySQL ---
echo; echo "-- MySQL (s3://mysql-backups/) --"
PITR_POD="$(k -n "$NS" get pods -l app.kubernetes.io/component=pitr -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
[[ -n "$PITR_POD" ]] || PITR_POD="$(k -n "$NS" get pods -o name | sed -n 's|^pod/\(mysql-pitr-.*\)|\1|p' | head -1)"
read -r READY RESTARTS STARTED NODE PUID <<<"$(k -n "$NS" get pod "$PITR_POD" -o jsonpath='{.status.containerStatuses[0].ready} {.status.containerStatuses[0].restartCount} {.status.startTime} {.spec.nodeName} {.metadata.uid}')"
LIMIT_MIB="$(k -n "$NS" get pod "$PITR_POD" -o jsonpath='{.spec.containers[0].resources.limits.memory}' | awk '/Gi$/ {print $1 * 1024; next} /Mi$/ {print $1 + 0}')"
if [[ "$READY $RESTARTS" == "true 0" ]]; then pass "Binlog collector up, no restarts" "$PITR_POD since $STARTED"; else
  fail "Binlog collector up, no restarts" "ready $READY, $RESTARTS restarts since $STARTED (kubectl -n $NS describe pod $PITR_POD)"; fi
PEAK_MIB="$(docker exec "$NODE" sh -c "cat \$(find /sys/fs/cgroup -maxdepth 4 -type d -name '*pod${PUID//-/_}*' | head -1)/memory.peak" 2>/dev/null | awk '{printf "%d", $1 / 1048576}')"
if [[ -n "$PEAK_MIB" && -n "$LIMIT_MIB" ]] && ((PEAK_MIB * 10 < LIMIT_MIB * 9)); then
  pass "Binlog collector memory peak under 90% of its limit (a 528 MiB buffer per upload)" "$PEAK_MIB of $LIMIT_MIB MiB"
else
  fail "Binlog collector memory peak under 90% of its limit (a 528 MiB buffer per upload)" "${PEAK_MIB:-?} of ${LIMIT_MIB:-?} MiB"
fi
MY_INV="$(inventory mysql mysql-backups)" || fail "mysql-backups listing" "failed"
if grep -q 'pitr-not-ready' <<<"$MY_INV"; then fail "No gap marker (pitr-not-ready)" "present: the operator refuses point-in-time restores"; else
  pass "No gap marker (pitr-not-ready)" "absent"; fi
# Binlogs: the union of every uploaded binlog's GTID set
EXECUTED="$(my_sql "$(my_nonwriter)" "SELECT @@GLOBAL.gtid_executed" | tr -d '\n')"
_gtids() {
  awk -F'\t' '$1 ~ /^binlog_.*-gtid-set$/ {print $1}' <<<"$(inventory mysql mysql-backups)" |
    while read -r key; do s3 mysql "mysql-backups/$key"; echo; done | python3 -c '
import sys
executed = sys.argv[1]
iv = {}
for line in sys.stdin:
    for part in line.strip().split(","):
        if ":" not in part:
            continue
        uuid, *ranges = part.split(":")
        for r in ranges:
            a, b = (r.split("-") + [r])[:2]
            iv.setdefault(uuid, []).append((int(a), int(b)))
out = []
for part in executed.split(","):
    uuid, *ranges = part.strip().split(":")
    want = max(int(r.split("-")[-1]) for r in ranges)
    merged = []
    for a, b in sorted(iv.get(uuid, [])):
        if merged and a <= merged[-1][1] + 1:
            merged[-1][1] = max(merged[-1][1], b)
        else:
            merged.append([a, b])
    have = merged[-1][1] if merged else 0
    out.append("%s %d %d %d %s" % (uuid, len(merged), want, have, " ".join("%d-%d" % tuple(m) for m in merged[:4])))
print("\n".join(out))' "$EXECUTED"
}
# Under load the cluster keeps executing: current means uploaded at least up
# to what it had executed when this run asked (EXECUTED, above)
_binlogs_current() { awk '$4 < $3 {exit 1}' <<<"$(_gtids)"; }
printf '  binlogs uploaded up to what the cluster had executed (the collector uploads every 60 s):'
wait_for 150 _binlogs_current || echo "  not after 150 s"
while read -r UUID INTERVALS WANT HAVE RANGES; do
  if [[ "$INTERVALS" == 1 ]]; then pass "Binlogs continuous (one GTID interval, ${UUID:0:8}…)" "$RANGES"; else
    fail "Binlogs continuous (one GTID interval, ${UUID:0:8}…)" "$INTERVALS intervals: $RANGES"; fi
  if ((HAVE >= WANT)); then pass "Binlogs current (uploaded up to what was executed at the start)" "$WANT, uploaded $HAVE"; else
    fail "Binlogs current (uploaded up to what was executed at the start)" "uploaded $HAVE, executed $WANT"; fi
done <<<"$(_gtids)"
# Full backups: each succeeded one's files are in the store; no files without a backup
DESTS="$(k -n "$NS" get perconaxtradbclusterbackups.pxc.percona.com -o jsonpath='{range .items[?(@.status.state=="Succeeded")]}{.metadata.name} {.status.destination}{"\n"}{end}')"
while read -r name dest; do
  [[ -n "$name" ]] || continue
  prefix="${dest#s3://mysql-backups/}/"
  read -r n b < <(awk -F'\t' -v p="$prefix" 'index($1, p) == 1 {n++; s += $2} END {print n + 0, s + 0}' <<<"$MY_INV")
  if ((n > 0)); then pass "Full backup $name in the store" "$n objects, $(mib "$b")"; else fail "Full backup $name in the store" "no objects under $prefix"; fi
done <<<"$DESTS"
for prefix in $(awk -F'\t' '$1 ~ /^mysql-.*-full\// {split($1, p, "/"); print p[1]}' <<<"$MY_INV" | sort -u); do
  grep -q "s3://mysql-backups/$prefix\$" <<<"$DESTS" ||
    warn "Files without a backup" "s3://mysql-backups/$prefix/ ($(awk -F'\t' -v p="$prefix/" 'index($1, p) == 1 {s += $2} END {printf "%.0f MiB", s / 1048576}' <<<"$MY_INV")): an orphan, delete by hand"
done
SCHEDULED="$(k -n "$NS" get perconaxtradbclusterbackups.pxc.percona.com -o name | grep -c '/cron-')"
if ((SCHEDULED <= MY_KEEP)); then pass "Scheduled full backups within keep $MY_KEEP" "$SCHEDULED (manual ones are not counted)"; else
  fail "Scheduled full backups within keep $MY_KEEP" "$SCHEDULED: retention is not deleting"; fi
BINLOG_BYTES="$(awk -F'\t' '$1 ~ /^binlog_/ {s += $2} END {print s + 0}' <<<"$MY_INV")"
echo "  binlogs in the store: $(grep -c $'^binlog_[^\t]*[0-9a-f]\t' <<<"$MY_INV") files, $(mib "$BINLOG_BYTES") (the collector never deletes them)"

echo
echo "  $WARN warning(s)"
summary "backup storage checks"
