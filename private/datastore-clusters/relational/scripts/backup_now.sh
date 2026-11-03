#!/usr/bin/env bash
# Take one full backup by hand (on demand), outside the weekly schedule, and
# report how long it took, how big it is and where it is in the store.
#   pg     a CloudNativePG Backup (method plugin): the Barman Cloud plugin
#          copies the data files from a replica (prefer-standby) to
#          s3://pg-backups/pg/base/<backup id>/, bzip2-compressed
#   mysql  a PerconaXtraDBClusterBackup: a Job joins Galera, a non-writer
#          node donates a copy (XtraBackup), the Job uploads it to
#          s3://mysql-backups/<destination>/
# The cluster keeps serving throughout. Backups taken by hand are not counted
# by the MySQL schedule's "keep 2"; PostgreSQL's 7-day recovery window covers
# every base backup in the store. Delete one by hand with kubectl delete
# (mysql: its percona.com/delete-backup finalizer, below, removes it from
# the store too).
# Usage: private/datastore-clusters/relational/scripts/backup_now.sh pg|mysql [dev]
# The run is logged in relational/logs/backup-<engine>-<UTC time>.txt.
# See docs/BACKUPS.md.

set -uo pipefail
source "$(dirname "$0")/../../../scripts/private_env.sh" # use_cluster, k, runbook_log
ENGINE="${1:-}"
ENV="${2:-dev}"
NS="relational"
KEYS="$HOME/.config/datastore-dev/backup-store/s3.json"
LIMIT=1800 # seconds; the PXC Job's own deadline is 1200 (runningDeadlineSeconds)
[[ "$ENGINE" == pg || "$ENGINE" == mysql ]] || {
  echo "Usage: $0 pg|mysql [dev]" >&2
  exit 2
}

# store_size <identity> <bucket> <prefix>: "<objects> <bytes>" under the
# prefix, listed from the laptop with that identity's key (from the key file;
# handed to curl on stdin, never printed)
store_size() {
  python3 - "$KEYS" "$@" <<'EOF'
import json, re, subprocess, sys, urllib.parse
keys, identity, bucket, prefix = sys.argv[1:]
c = next(i for i in json.load(open(keys))["identities"] if i["name"] == identity)["credentials"][0]
count = size = 0
token = ""
while True:
    q = "list-type=2&prefix=" + urllib.parse.quote(prefix) + (("&continuation-token=" + urllib.parse.quote(token)) if token else "")
    out = subprocess.run(["curl", "-s", "--aws-sigv4", "aws:amz:us-east-1:s3", "-K", "-", f"http://localhost:8333/{bucket}?{q}"],
                         input=f'user = "{c["accessKey"]}:{c["secretKey"]}"', capture_output=True, text=True).stdout
    if "<ListBucketResult" not in out:
        sys.exit("store listing failed: " + out[:80])
    sizes = re.findall(r"<Size>(\d+)</Size>", out)
    count += len(sizes)
    size += sum(map(int, sizes))
    m = re.search(r"<NextContinuationToken>([^<]+)</NextContinuationToken>", out)
    if "<IsTruncated>true</IsTruncated>" not in out or not m:
        break
    token = m.group(1)
print(count, size)
EOF
}

mib() { awk -v b="$1" 'BEGIN { printf "%.1f MiB", b / 1048576 }'; }

# wait_backup <kind> <name> <status field> <done> <failed>: poll every 10 s
# until the status field reads done (return 0) or failed (1), or LIMIT
wait_backup() {
  local state="" last=""
  while ((SECONDS - START < LIMIT)); do
    state="$(k -n "$NS" get "$1" "$2" -o jsonpath="{.status.$3}" 2>/dev/null)"
    [[ "$state" != "$last" ]] && echo "  $(date -u +%H:%M:%S) ${state:-(no status yet)}"
    last="$state"
    [[ "$state" == "$4" ]] && return 0
    [[ "$state" == "$5" ]] && return 1
    sleep 10
  done
  echo "  gave up after ${LIMIT}s"
  return 1
}

use_cluster "datastore-$ENV"
runbook_log "$(dirname "$0")/../logs" "backup-$ENGINE" "$@"
[[ -f "$KEYS" ]] || { echo "No $KEYS: see docs/BACKUPS.md"; exit 1; }
NAME="$ENGINE-manual-$(date -u +%Y%m%d-%H%M%S)"
BUCKET="$ENGINE-backups"

echo "Store before: $BUCKET holds $(store_size "$ENGINE" "$BUCKET" "" | { read -r n b; echo "$n objects, $(mib "$b")"; })"
START=$SECONDS

if [[ "$ENGINE" == pg ]]; then
  echo "Backup $NAME of cluster pg (plugin, from a replica)"
  k -n "$NS" apply -f - <<EOF || exit 1
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: $NAME
  namespace: $NS
spec:
  cluster:
    name: pg
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
  target: prefer-standby
EOF
  wait_backup backups.postgresql.cnpg.io "$NAME" phase completed failed
  OK=$?
  k -n "$NS" get backups.postgresql.cnpg.io "$NAME" -o jsonpath='  from {.status.instanceID.podName}, id {.status.backupId}, WAL {.status.beginWal} to {.status.endWal}{"\n"}  started {.status.startedAt}, stopped {.status.stoppedAt}{"\n"}  {.status.error}{"\n"}'
  ID="$(k -n "$NS" get backups.postgresql.cnpg.io "$NAME" -o jsonpath='{.status.backupId}')"
  PREFIX="pg/base/$ID/"
else
  echo "Backup $NAME of cluster mysql (backup Job, a non-writer node donates)"
  k -n "$NS" apply -f - <<EOF || exit 1
apiVersion: pxc.percona.com/v1
kind: PerconaXtraDBClusterBackup
metadata:
  name: $NAME
  namespace: $NS
  finalizers:
    - percona.com/delete-backup # deleting it also deletes it from the store
spec:
  pxcCluster: mysql
  storageName: s3
EOF
  wait_backup perconaxtradbclusterbackups.pxc.percona.com "$NAME" state Succeeded Failed
  OK=$?
  k -n "$NS" get perconaxtradbclusterbackups.pxc.percona.com "$NAME" -o jsonpath='  to {.status.destination}{"\n"}  completed {.status.completed}{"\n"}  {.status.error}{"\n"}'
  DEST="$(k -n "$NS" get perconaxtradbclusterbackups.pxc.percona.com "$NAME" -o jsonpath='{.status.destination}')"
  PREFIX="${DEST#s3://"$BUCKET"/}/"
fi

echo "Took $((SECONDS - START)) s (from creating it to the status above)"
((OK == 0)) || { echo "FAILED: backup $NAME did not complete (kubectl -n $NS describe it, and the Job or plugin logs)"; exit 1; }
[[ "$PREFIX" == */ && "$PREFIX" != / ]] || { echo "FAILED: no location in the status"; exit 1; }
read -r N B < <(store_size "$ENGINE" "$BUCKET" "$PREFIX")
echo "In the store: s3://$BUCKET/$PREFIX: ${N:-0} objects, $(mib "${B:-0}")"
((${N:-0} > 0)) || { echo "FAILED: nothing in the store under that prefix"; exit 1; }
echo "Store after: $BUCKET holds $(store_size "$ENGINE" "$BUCKET" "" | { read -r n b; echo "$n objects, $(mib "$b")"; })"
