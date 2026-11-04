#!/usr/bin/env bash
# The backup store's bucket settings, on every bucket, then read back:
#   encryption   default SSE-S3 (AES-256): the store encrypts every object it
#                is given, whatever the client sends (the PXC operator's
#                uploader, xbcloud, asks for none)
#   object lock  on (versioning comes with it), default retention COMPLIANCE
#                for --lock-days days: no key, not even admin, can delete or
#                overwrite a backup's stored version before then; a delete
#                only adds a delete marker. Turning lock on is irreversible;
#                the days can be changed later (for new objects only)
#   lifecycle    "old-versions": a version replaced or deleted is removed a
#                day after its lock allows it; leftover delete markers too
# Objects already stored keep their old settings (plain, unlocked);
# retention replaces them. Store settings, not Terraform's: they need the
# admin key (s3.json), which stays out of state, and the lock is turned on
# through the store's shell. Rerun whenever the store's data volume is new
# (platform check_resources.sh reports a bucket without them).
# Usage: private/datastore-clusters/platform/scripts/backup_store_buckets.sh [--lock-days N]   (default 7)
# docs/BACKUPS.md, "Encryption" and "Object lock".

set -euo pipefail
DIR="$HOME/.config/datastore-dev/backup-store"
STORE=datastore-backups
BUCKETS="pg-backups mysql-backups"
URL="https://localhost:8333"
# At most the shortest retention (pg's 7-day window): a lock longer than
# retention keeps what the operators delete for longer
LOCK_DAYS=7
[[ "${1:-}" == --lock-days ]] && LOCK_DAYS="${2:?--lock-days needs a number}"
[[ "$LOCK_DAYS" =~ ^[1-9][0-9]*$ ]] || {
  echo "--lock-days: a whole number of days, 1 or more" >&2
  exit 1
}
[[ -f "$DIR/s3.json" && -f "$DIR/ca.crt" ]] || {
  echo "No $DIR/s3.json or ca.crt: run backup_store_keys.sh and backup_store_tls.sh, then apply backup-store" >&2
  exit 1
}

# as_admin <curl arguments>: a request with the admin key and the store's CA,
# both handed to curl as a config file on stdin (the key never on argv)
as_admin() {
  python3 -c '
import json, sys
c = next(i for i in json.load(open(sys.argv[1]))["identities"] if i["name"] == "admin")["credentials"][0]
print("user = \"" + c["accessKey"] + ":" + c["secretKey"] + "\"")
print("cacert = \"" + sys.argv[2] + "\"")' "$DIR/s3.json" "$DIR/ca.crt" |
    curl -s --aws-sigv4 "aws:amz:us-east-1:s3" -K - "$@"
}
# put <bucket> <subresource> <xml>: set a bucket setting, or stop
put() {
  local code
  code="$(as_admin -o /dev/null -w '%{http_code}' -X PUT -H 'Content-Type: application/xml' --data "$3" "$URL/$1?$2")"
  [[ "$code" == 200 ]] || {
    echo "$1: setting $2 failed (HTTP $code)" >&2
    exit 1
  }
}
# field <bucket> <subresource> <element>: one value from a bucket setting
field() { as_admin "$URL/$1?$2" | sed -n "s:.*<$3>\([^<]*\)</$3>.*:\1:p"; }

ENCRYPTION='<ServerSideEncryptionConfiguration><Rule><ApplyServerSideEncryptionByDefault><SSEAlgorithm>AES256</SSEAlgorithm></ApplyServerSideEncryptionByDefault></Rule></ServerSideEncryptionConfiguration>'
RETENTION="<ObjectLockConfiguration><ObjectLockEnabled>Enabled</ObjectLockEnabled><Rule><DefaultRetention><Mode>COMPLIANCE</Mode><Days>$LOCK_DAYS</Days></DefaultRetention></Rule></ObjectLockConfiguration>"
LIFECYCLE='<LifecycleConfiguration><Rule><ID>old-versions</ID><Status>Enabled</Status><Filter><Prefix></Prefix></Filter><NoncurrentVersionExpiration><NoncurrentDays>1</NoncurrentDays></NoncurrentVersionExpiration><Expiration><ExpiredObjectDeleteMarker>true</ExpiredObjectDeleteMarker></Expiration></Rule></LifecycleConfiguration>'

for b in $BUCKETS; do
  put "$b" encryption "$ENCRYPTION"
  if [[ "$(field "$b" object-lock ObjectLockEnabled)" != Enabled ]]; then
    # Over S3 a bucket gets lock only when created; the store's shell turns
    # it on for an existing one (and versioning with it)
    docker exec "$STORE" sh -c "echo 's3.bucket.lock -name $b -enable' | weed shell" | grep -q 'enabled successfully' || {
      echo "$b: turning object lock on failed (docker exec $STORE ... s3.bucket.lock)" >&2
      exit 1
    }
  fi
  put "$b" object-lock "$RETENTION"
  put "$b" lifecycle "$LIFECYCLE"
  echo "$b: encryption $(field "$b" encryption SSEAlgorithm), versioning $(field "$b" versioning Status)," \
    "lock $(field "$b" object-lock Mode) $(field "$b" object-lock Days) days, lifecycle $(field "$b" lifecycle ID)"
  [[ "$(field "$b" object-lock Mode) $(field "$b" object-lock Days)" == "COMPLIANCE $LOCK_DAYS" ]] || exit 1
done
