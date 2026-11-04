#!/usr/bin/env bash
# Make the backup store's keys, in a folder outside the repo, readable by you
# only, that the store mounts read-only (environments/dev/backup-store): the
# keys never enter Terraform state or git. docs/BACKUPS.md, "Where the keys
# are", lists every file.
#   s3.json        one S3 identity per engine, each allowed only its own
#                  bucket (<engine>-backups), and "admin" for the store's own
#                  settings (bucket encryption; backup_store_buckets.sh),
#                  used from the laptop only, never given to a cluster.
#                  Nothing anonymous.
#   security.toml  the store's encryption key (KEK, [s3.sse]): it encrypts
#                  the key of every object stored encrypted. Without it the
#                  store would make its own, on the data volume beside the
#                  data it protects. Made once, never replaced: a new one
#                  makes every encrypted backup unreadable.
# Keeps existing files unless --rotate (s3.json only; an older s3.json
# without "admin" gets it added, the engine keys kept). Restarts the store
# if it runs and a file changed (after a rotation the engines' Secrets need
# updating too: relational/scripts/backup_secrets.sh).
# Usage: private/datastore-clusters/platform/scripts/backup_store_keys.sh [--rotate]
# Writes: ~/.config/datastore-dev/backup-store/{s3.json,security.toml} (prints no key)

set -euo pipefail
DIR="$HOME/.config/datastore-dev/backup-store"
FILE="$DIR/s3.json"
KEK_FILE="$DIR/security.toml"
STORE=datastore-backups
ENGINES="pg mysql"
changed=""

# rand <length> <characters>: random string from /dev/urandom (tr stops on
# SIGPIPE when head has enough: not a failure)
rand() { LC_ALL=C tr -dc "$2" </dev/urandom 2>/dev/null | head -c "$1" || true; }
# identity <name> <actions as JSON strings>: one identity with a new key
identity() {
  printf '\n    {\n      "name": "%s",\n      "credentials": [{ "accessKey": "%s", "secretKey": "%s" }],\n      "actions": [%s]\n    }' \
    "$1" "$(rand 20 'A-Z0-9')" "$(rand 40 'A-Za-z0-9')" "$2"
}

mkdir -p "$DIR"
chmod 700 "$DIR"
umask 077

if [[ ! -f "$FILE" || "${1:-}" == --rotate ]]; then
  identities=""
  for e in $ENGINES; do
    b="$e-backups"
    identities+="${identities:+,}$(identity "$e" "\"Read:$b\", \"Write:$b\", \"List:$b\", \"Tagging:$b\"")"
  done
  identities+=",$(identity admin '"Admin"')"
  tmp="$(mktemp "$DIR/.s3.json.XXXXXX")"
  printf '{\n  "identities": [%s\n  ]\n}\n' "$identities" >"$tmp"
  python3 -m json.tool "$tmp" >/dev/null # valid JSON, or stop before replacing the file
  mv "$tmp" "$FILE"
  echo "Wrote $FILE: identities $(echo $ENGINES) admin, buckets $(printf '%s-backups ' $ENGINES)"
  changed=1
elif ! python3 -c 'import json, sys; sys.exit(not any(i["name"] == "admin" for i in json.load(open(sys.argv[1]))["identities"]))' "$FILE"; then
  tmp="$(mktemp "$DIR/.s3.json.XXXXXX")"
  python3 - "$FILE" "$(identity admin '"Admin"')" >"$tmp" <<'EOF'
import json, sys
keys = json.load(open(sys.argv[1]))
keys["identities"].append(json.loads(sys.argv[2]))
print(json.dumps(keys, indent=2))
EOF
  mv "$tmp" "$FILE"
  echo "Added identity admin to $FILE (engine keys unchanged)"
  changed=1
else
  echo "Keys exist: $FILE (unchanged; --rotate to replace them)"
fi

if [[ ! -f "$KEK_FILE" ]]; then
  tmp="$(mktemp "$DIR/.security.toml.XXXXXX")"
  printf '# SeaweedFS: the key that encrypts each encrypted object'"'"'s own key (SSE-S3).\n# Never replace it: every encrypted backup needs it. docs/BACKUPS.md\n[s3.sse]\nkek = "%s"\n' \
    "$(openssl rand -hex 32)" >"$tmp"
  mv "$tmp" "$KEK_FILE"
  echo "Wrote $KEK_FILE: the store's encryption key (back it up; never replace it)"
  changed=1
else
  echo "Encryption key exists: $KEK_FILE (never replaced)"
fi

if [[ -n "$changed" && "$(docker inspect -f '{{.State.Running}}' "$STORE" 2>/dev/null)" == true ]]; then
  docker restart "$STORE" >/dev/null
  echo "Restarted $STORE with the new keys"
fi
