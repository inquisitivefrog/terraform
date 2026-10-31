#!/usr/bin/env bash
# Make the backup store's keys: one S3 identity per engine, each allowed only
# its own bucket (<engine>-backups), nothing anonymous. Written to a file
# outside the repo, readable by you only, that the store mounts read-only
# (environments/dev/backup-store): the keys never enter Terraform state.
# Keeps an existing file unless --rotate; after a rotation it restarts the
# store if it runs (the engines' Secrets then need updating too).
# Usage: private/datastore-clusters/platform/scripts/backup_store_keys.sh [--rotate]
# Writes: ~/.config/datastore-dev/backup-store/s3.json (prints no key)

set -euo pipefail
DIR="$HOME/.config/datastore-dev/backup-store"
FILE="$DIR/s3.json"
STORE=datastore-backups
ENGINES="pg mysql"

if [[ -f "$FILE" && "${1:-}" != --rotate ]]; then
  echo "Keys exist: $FILE (unchanged; --rotate to replace them)"
  exit 0
fi

# rand <length> <characters>: random string from /dev/urandom (tr stops on
# SIGPIPE when head has enough: not a failure)
rand() { LC_ALL=C tr -dc "$2" </dev/urandom 2>/dev/null | head -c "$1" || true; }

identities=""
for e in $ENGINES; do
  b="$e-backups"
  identities+="${identities:+,}
    {
      \"name\": \"$e\",
      \"credentials\": [{ \"accessKey\": \"$(rand 20 'A-Z0-9')\", \"secretKey\": \"$(rand 40 'A-Za-z0-9')\" }],
      \"actions\": [\"Read:$b\", \"Write:$b\", \"List:$b\", \"Tagging:$b\"]
    }"
done

mkdir -p "$DIR"
chmod 700 "$DIR"
umask 077
tmp="$(mktemp "$DIR/.s3.json.XXXXXX")"
printf '{\n  "identities": [%s\n  ]\n}\n' "$identities" >"$tmp"
python3 -m json.tool "$tmp" >/dev/null # valid JSON, or stop before replacing the file
mv "$tmp" "$FILE"
echo "Wrote $FILE: identities $(echo $ENGINES), buckets $(printf '%s-backups ' $ENGINES)"

if [[ "$(docker inspect -f '{{.State.Running}}' "$STORE" 2>/dev/null)" == true ]]; then
  docker restart "$STORE" >/dev/null
  echo "Restarted $STORE with the new keys"
fi
