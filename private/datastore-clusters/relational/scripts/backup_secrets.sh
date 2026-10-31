#!/usr/bin/env bash
# Give each database cluster its key to the backup store: one Kubernetes
# Secret per engine in the relational namespace, from the store's key file
# (platform/scripts/backup_store_keys.sh). Not Terraform: a Secret it made
# would put the keys in its state. Run it before applying the clusters root
# with backups on, and again after backup_store_keys.sh --rotate.
#   pg-backup-s3     ACCESS_KEY_ID, ACCESS_SECRET_KEY: read by the Barman
#                    Cloud plugin's ObjectStore (pg-backups bucket)
#   mysql-backup-s3  AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY: the names the
#                    PXC operator requires (mysql-backups bucket)
# The keys go to kubectl on stdin: never on a command line, never printed.
# Usage: private/datastore-clusters/relational/scripts/backup_secrets.sh [dev]
# See docs/BACKUPS.md.

set -euo pipefail
source "$(dirname "$0")/../../../scripts/private_env.sh" # use_cluster, k
ENV="${1:-dev}"
KEYS="$HOME/.config/datastore-dev/backup-store/s3.json"
NS=relational
[[ -f "$KEYS" ]] || {
  echo "No $KEYS: run private/datastore-clusters/platform/scripts/backup_store_keys.sh" >&2
  exit 1
}
use_cluster "datastore-$ENV"
k get namespace "$NS" >/dev/null || {
  echo "No namespace $NS: apply the relational clusters root first" >&2
  exit 1
}

# secret <identity> <name> <access key field> <secret key field>: the Secret
# as JSON, from that identity's key in $KEYS
secret() {
  python3 - "$KEYS" "$NS" "$@" <<'EOF'
import json, sys
keys, ns, identity, name, akey, skey = sys.argv[1:]
c = next(i for i in json.load(open(keys))["identities"] if i["name"] == identity)["credentials"][0]
print(json.dumps({
    "apiVersion": "v1", "kind": "Secret",
    "metadata": {"name": name, "namespace": ns,
                 "labels": {"app.kubernetes.io/part-of": "backups"}},
    "type": "Opaque",
    "stringData": {akey: c["accessKey"], skey: c["secretKey"]},
}))
EOF
}

secret pg pg-backup-s3 ACCESS_KEY_ID ACCESS_SECRET_KEY | k apply -f -
secret mysql mysql-backup-s3 AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY | k apply -f -
