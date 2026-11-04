#!/usr/bin/env bash
# Turn on default encryption (SSE-S3, AES-256) on every bucket in the backup
# store, then read it back. From then on the store encrypts every object it
# is given, whatever the client sends: the PXC operator's uploader (xbcloud)
# asks for no encryption, so this is the only way to get it for MySQL.
# Objects already stored stay as they were; retention replaces them.
# A store setting, not Terraform's: it needs the admin key (s3.json), which
# stays out of state. Rerun it whenever the store's data volume is new
# (platform check_resources.sh reports a bucket without it).
# Usage: private/datastore-clusters/platform/scripts/backup_store_buckets.sh
# docs/BACKUPS.md, "Encryption".

set -euo pipefail
DIR="$HOME/.config/datastore-dev/backup-store"
BUCKETS="pg-backups mysql-backups"
URL="https://localhost:8333"
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

RULE='<ServerSideEncryptionConfiguration><Rule><ApplyServerSideEncryptionByDefault><SSEAlgorithm>AES256</SSEAlgorithm></ApplyServerSideEncryptionByDefault></Rule></ServerSideEncryptionConfiguration>'
for b in $BUCKETS; do
  code="$(as_admin -o /dev/null -w '%{http_code}' -X PUT -H 'Content-Type: application/xml' --data "$RULE" "$URL/$b?encryption")"
  [[ "$code" == 200 ]] || {
    echo "$b: setting default encryption failed (HTTP $code)" >&2
    exit 1
  }
  algo="$(as_admin "$URL/$b?encryption" | sed -n 's:.*<SSEAlgorithm>\([^<]*\)</SSEAlgorithm>.*:\1:p')"
  echo "$b: default encryption ${algo:-none}"
  [[ "$algo" == AES256 ]] || exit 1
done
