#!/usr/bin/env bash
# Runbook 7, object lock: prove a backup in the store can't be deleted or
# changed before its lock date, by the engine's own key (what a stolen one
# could do) or the admin key, and that a "deleted" backup comes back.
# Needs the buckets locked (platform/scripts/backup_store_buckets.sh) and a
# backup of each engine taken since (relational/scripts/backup_now.sh).
#   check   (default) the settings; the newest pg base backup and MySQL full
#           backup carry a COMPLIANCE lock; then, on a small canary object
#           per bucket (lock-canary/<engine>-<time>, written with the
#           engine's key, locked like any backup): delete only hides it
#           (delete marker), deleting the version is refused (engine, admin,
#           admin with the governance bypass), shortening its lock is
#           refused, an overwrite keeps the original, versioning can't be
#           suspended, and removing the delete marker brings it back.
#           Real backups are only read.
#   expire  after the lock days, run daily until the canaries are gone: the
#           replaced version is removed by the store itself (the lifecycle
#           rule, a day after its lock; failed if still there 2 days after),
#           then the current one, its lock over, is deleted with the admin
#           key (refused while locked).
# Not on the live store (tested on a throwaway one, 2026-11-04): deleting a
# locked bucket, over S3 or the store's shell (both refused).
# Usage: private/datastore-clusters/relational/scripts/runbook_7_lock.sh [check|expire] [dev]
# Log: relational/logs/runbook-7-lock-<mode>-<time>.txt (-FAILED.txt if it fails)

MODE="${1:-check}"
[[ "$MODE" == check || "$MODE" == expire ]] || {
  echo "Usage: $0 [check|expire] [dev]" >&2
  exit 1
}
ENV="${2:-dev}"
ENGINE=mysql # for the library's engine switch; this runbook covers both
source "$(dirname "$0")/runbook_lib.sh" # pass, fail, summary, s3, inventory
DIR="$HOME/.config/datastore-dev/backup-store"
CANARY=lock-canary
declare -A BUCKET=([pg]=pg-backups [mysql]=mysql-backups)

use_cluster "datastore-$ENV"
runbook_log "$LIB_DIR/../logs" "runbook-7-lock-$MODE" "$@"
echo "== Runbook 7: object lock, $MODE ($(date -u +%Y-%m-%dT%H:%M:%SZ)) =="

# req <identity> <method> <path> [curl args]: a request with that identity's
# key and the store's CA (curl's config on stdin: the key never on argv,
# never printed); the path percent-encoded. Prints the body, then the HTTP
# status on a line of its own.
req() {
  python3 - "$DIR/s3.json" "$DIR/ca.crt" "$@" <<'EOF'
import json, subprocess, sys, urllib.parse
keys, ca, identity, method, path, *rest = sys.argv[1:]
c = next(i for i in json.load(open(keys))["identities"] if i["name"] == identity)["credentials"][0]
p, q = (path.split("?", 1) + [""])[:2]
url = "https://localhost:8333/" + urllib.parse.quote(p) + ("?" + q if q else "")
args = ["-I"] if method == "HEAD" else ["-X", method]
r = subprocess.run(["curl", "-s", *args, "--aws-sigv4", "aws:amz:us-east-1:s3", "-K", "-", *rest, url, "-w", "\n%{http_code}"],
                   input=f'user = "{c["accessKey"]}:{c["secretKey"]}"\ncacert = "{ca}"', capture_output=True, text=True)
sys.stdout.write(r.stdout + "\n")
EOF
}
code() { req "$@" -o /dev/null | tail -1; }
body() { req "$@" | sed '$d'; }
# lock_of <identity> <path>: "<mode> <retain-until>" of the current version
lock_of() {
  req "$1" HEAD "$2" | tr -d '\r' | awk -F': ' 'tolower($1) == "x-amz-object-lock-mode" {m = $2}
    tolower($1) == "x-amz-object-lock-retain-until-date" {u = $2} END {print (m ? m : "none"), (u ? u : "-")}'
}
# versions <bucket> <prefix>: "<version|marker> <key> <version id> <latest> <modified>", every version, paginated
versions() {
  local km="" vm="" page
  while :; do
    page="$(body admin GET "$1?versions&prefix=$2${km:+&key-marker=$km}${vm:+&version-id-marker=$vm}")"
    python3 -c '
import re, sys
x = sys.stdin.read()
for kind, item in re.findall(r"<(Version|DeleteMarker)>(.*?)</(?:Version|DeleteMarker)>", x, re.S):
    f = lambda e: (re.search("<" + e + ">([^<]*)</" + e + ">", item) or [None, "-"])[1]
    print("version" if kind == "Version" else "marker", f("Key"), f("VersionId"), f("IsLatest"), f("LastModified"))' <<<"$page"
    grep -q '<IsTruncated>true</IsTruncated>' <<<"$page" || break
    km="$(sed -n 's:.*<NextKeyMarker>\([^<]*\)</NextKeyMarker>.*:\1:p' <<<"$page")"
    vm="$(sed -n 's:.*<NextVersionIdMarker>\([^<]*\)</NextVersionIdMarker>.*:\1:p' <<<"$page")"
  done
}
# future <RFC 3339 time>: true if later than now
future() { python3 -c 'import datetime as d, sys; sys.exit(not d.datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00")) > d.datetime.now(d.timezone.utc))' "$1"; }
# days_from_now <RFC 3339 time>: whole hours from now, as days with one decimal
days_from_now() { python3 -c 'import datetime as d, sys; t = d.datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00")); print("%.1f" % ((t - d.datetime.now(d.timezone.utc)).total_seconds() / 86400))' "$1"; }
field() { sed -n "s:.*<$1>\([^<]*\)</$1>.*:\1:p"; }

if [[ "$MODE" == check ]]; then
  echo; echo "-- settings --"
  for e in pg mysql; do
    b="${BUCKET[$e]}"
    cfg="$(body admin GET "$b?object-lock")"
    match "$b object lock COMPLIANCE" '^Enabled COMPLIANCE [0-9]+$' echo "$(field ObjectLockEnabled <<<"$cfg") $(field Mode <<<"$cfg") $(field Days <<<"$cfg")"
    expect "$b versioning on" "Enabled" sh -c "printf '%s' '$(body admin GET "$b?versioning" | field Status)'"
  done
  DAYS="$(body admin GET "pg-backups?object-lock" | field Days)"
  echo "  lock period: ${DAYS:-?} days"

  echo; echo "-- the newest backups are locked --"
  PG_BASE="$(inventory pg pg-backups | awk -F'\t' '$1 ~ /^pg\/base\/[^\/]+\/data\.tar/ {print $3 "\t" $1}' | sort | tail -1 | cut -f2)"
  read -r mode until <<<"$(lock_of pg "pg-backups/$PG_BASE")"
  if [[ "$mode" == COMPLIANCE ]] && future "$until"; then pass "pg newest base backup locked" "$PG_BASE until $until"; else
    fail "pg newest base backup locked" "${PG_BASE:-none}: $mode $until (taken before the lock? backup_now.sh pg)"; fi
  MY_DEST="$(k -n "$NS" get perconaxtradbclusterbackups.pxc.percona.com -o json |
    jq -r '[.items[] | select(.status.state == "Succeeded")] | sort_by(.status.completed) | last | .status.destination // empty')"
  MY_PREFIX="${MY_DEST#s3://mysql-backups/}/"
  MY_OBJ="$(inventory mysql mysql-backups | awk -F'\t' -v p="$MY_PREFIX" 'index($1, p) == 1 {print $1; exit}')"
  read -r mode until <<<"$(lock_of mysql "mysql-backups/$MY_OBJ")"
  if [[ "$mode" == COMPLIANCE ]] && future "$until"; then pass "MySQL newest full backup locked" "$MY_OBJ until $until"; else
    fail "MySQL newest full backup locked" "${MY_OBJ:-none}: $mode $until (taken before the lock? backup_now.sh mysql)"; fi

  for e in pg mysql; do
    b="${BUCKET[$e]}"
    key="$CANARY/$e-$(date -u +%Y%m%dT%H%M%S)"
    echo; echo "-- $b: canary $key, written with the $e key --"
    expect "Write" "200" code "$e" PUT "$b/$key" --data "original $key"
    read -r mode until <<<"$(lock_of "$e" "$b/$key")"
    if [[ "$mode" == COMPLIANCE ]] && future "$until"; then pass "Locked as it was written" "$mode until $until ($(days_from_now "$until") days)"; else
      fail "Locked as it was written" "$mode $until"; fi
    VID="$(versions "$b" "$key" | awk '$1 == "version" {print $3; exit}')"
    expect "Delete with the $e key: accepted, as a delete marker" "204" code "$e" DELETE "$b/$key"
    expect "  ...and the object is hidden" "404" code "$e" GET "$b/$key"
    expect "  ...but its version is still there" "version" sh -c "printf '%s' '$(versions "$b" "$key" | awk -v v="$VID" '$3 == v {print $1}')'"
    expect "Delete the version, $e key: refused" "403" code "$e" DELETE "$b/$key?versionId=$VID"
    expect "Delete the version, admin key: refused" "403" code admin DELETE "$b/$key?versionId=$VID"
    expect "Delete the version, admin key with the governance bypass: refused" "403" code admin DELETE "$b/$key?versionId=$VID" \
      -H 'x-amz-bypass-governance-retention: true'
    soon="$(date -u -v+1H +%Y-%m-%dT%H:%M:%SZ)"
    expect "Shorten its lock (to an hour), admin key: refused" "403" code admin PUT "$b/$key?retention&versionId=$VID" \
      -H 'Content-Type: application/xml' --data "<Retention><Mode>COMPLIANCE</Mode><RetainUntilDate>$soon</RetainUntilDate></Retention>"
    expect "The version reads back unchanged" "original $key" body "$e" GET "$b/$key?versionId=$VID"
    MARKER="$(versions "$b" "$key" | awk '$1 == "marker" && $4 == "true" {print $3; exit}')"
    expect "Recover: remove the delete marker" "204" code "$e" DELETE "$b/$key?versionId=$MARKER"
    expect "  ...and the object is back" "original $key" body "$e" GET "$b/$key"
    expect "Overwrite with the $e key: accepted, as a new version" "200" code "$e" PUT "$b/$key" --data "overwritten"
    expect "  ...current is the new one" "overwritten" body "$e" GET "$b/$key"
    expect "  ...the original is kept" "original $key" body "$e" GET "$b/$key?versionId=$VID"
    # Refused on a locked bucket; if not, put it back and fail
    c="$(code admin PUT "$b?versioning" -H 'Content-Type: application/xml' --data '<VersioningConfiguration><Status>Suspended</Status></VersioningConfiguration>')"
    if [[ "$c" == 409 ]]; then pass "Suspend versioning, admin key: refused" "$c"; else
      code admin PUT "$b?versioning" -H 'Content-Type: application/xml' --data '<VersioningConfiguration><Status>Enabled</Status></VersioningConfiguration>' >/dev/null
      fail "Suspend versioning, admin key: refused" "$c (versioning turned back on)"; fi
    echo "  canary $b/$key: 2 versions, locked until $until; check after: $0 expire"
  done
else
  # Per canary: its replaced version (the original) is left to the
  # lifecycle rule, which may take a day after the lock ends (failed at 2);
  # the current one is deleted with the admin key once its lock is over and
  # nothing older is left (deleting it would bring an older one back).
  WAITING=0
  for e in pg mysql; do
    b="${BUCKET[$e]}"
    echo; echo "-- $b: canaries --"
    ALL="$(versions "$b" "$CANARY/" | awk '$1 == "version"')"
    [[ -n "$ALL" ]] || { echo "  none left"; continue; }
    for key in $(awk '{print $2}' <<<"$ALL" | sort -u); do
      older=0
      while read -r kind k vid latest modified; do
        read -r mode until <<<"$(lock_of admin "$b/$k?versionId=$vid")"
        if [[ "$latest" == false ]]; then
          older=$((older + 1))
          if [[ "$until" != - ]] && future "$until"; then
            echo "  $key: replaced version locked $(days_from_now "$until") more days"
            WAITING=$((WAITING + 1))
          elif [[ "$until" != - ]] && python3 -c "import sys; sys.exit(not float(sys.argv[1]) <= -2)" "$(days_from_now "$until")"; then
            fail "Lifecycle removed $key's replaced version a day after its lock" "still there, lock ended $until"
          else
            echo "  $key: replaced version's lock ended ${until}: the lifecycle rule may take a day"
            WAITING=$((WAITING + 1))
          fi
        else
          CUR_VID="$vid" CUR_UNTIL="$until"
        fi
      done <<<"$(awk -v k="$key" '$2 == k' <<<"$ALL")"
      ((older == 0)) && pass "Lifecycle: $key's replaced version gone" "removed by the store"
      if [[ "$CUR_UNTIL" != - ]] && future "$CUR_UNTIL"; then
        echo "  $key: current version locked $(days_from_now "$CUR_UNTIL") more days (until $CUR_UNTIL)"
      elif ((older > 0)); then
        echo "  $key: current version's lock is over; deleted once the replaced one is gone"
      else
        expect "Lock over: $key deletable (admin key)" "204" code admin DELETE "$b/$key?versionId=$CUR_VID"
      fi
    done
  done
fi
# Nothing failed but versions still wait for the store: not a pass yet
if [[ "$MODE" == expire && "$FAIL" -eq 0 && "$WAITING" -gt 0 ]]; then
  echo
  echo "== Not finished: $WAITING canary versions waiting for their lock or the lifecycle rule ($PASS passed, 0 failed) =="
  echo "Run again tomorrow: $0 expire"
  exit 0
fi
summary "object lock checks"
