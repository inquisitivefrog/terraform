#!/usr/bin/env bash
# Runbook 7, the schedule: watch scheduled full backups fire on both engines
# and MySQL's retention delete the oldest beyond keep, files included. The
# weekly schedule never fires during a session, so this needs a short one,
# applied by hand first and removed after (relational clusters root):
#   terraform apply -var 'pg_backup_schedule=0 */15 * * * *' -var 'mysql_backup_schedule=*/15 * * * *'
#   ... this script ...
#   terraform apply            (back to weekly)
# Watches only; changes nothing. Checks:
#   pg     each fire makes a Backup that completes, from a replica, with its
#          files in the store. Retention (a 7-day recovery window) can't be
#          seen in an hour: these backups stay until it passes.
#   mysql  each fire makes a backup that succeeds; once more than keep (2)
#          have succeeded, the oldest is deleted, from the store too; at the
#          end exactly keep remain. Backups taken by hand are not counted.
# Default 4 fires each (an hour at every 15 minutes): 2 MySQL deletions.
# Costs per fire about 185 MiB (pg) and 775 MiB (mysql, until deleted).
# Usage: private/datastore-clusters/relational/scripts/runbook_7_schedule.sh [fires=4] [dev]
# Log: relational/logs/runbook-7-schedule-<time>.txt (-FAILED.txt if it fails)

FIRES="${1:-4}"
ENV="${2:-dev}"
ENGINE=mysql # for the library's engine switch; this runbook covers both
source "$(dirname "$0")/runbook_lib.sh" # inventory, mib; checks.sh: pass, fail, summary
MY_KEEP=2 # clusters root, keep
POLL=30
[[ "$FIRES" =~ ^[0-9]+$ ]] && ((FIRES > MY_KEEP)) || die "fires must be more than keep ($MY_KEEP) to see a deletion"

use_cluster "datastore-$ENV"
runbook_log "$LIB_DIR/../logs" "runbook-7-schedule" "$@"
echo "== Runbook 7: scheduled backups and retention ($(date -u +%Y-%m-%dT%H:%M:%SZ)) =="

# --- preconditions: a short schedule is applied ---
PG_SCHED="$(k -n "$NS" get scheduledbackups.postgresql.cnpg.io pg-scheduled -o jsonpath='{.spec.schedule}')"
MY_SCHED="$(k -n "$NS" get perconaxtradbclusters.pxc.percona.com mysql -o jsonpath='{.spec.backup.schedule[0].schedule}')"
echo "  schedules: pg '$PG_SCHED', mysql '$MY_SCHED'"
[[ "$PG_SCHED" != "0 0 3 * * 0" && "$MY_SCHED" != "0 3 * * 0" ]] ||
  die "still weekly: apply the short schedule first (see this script's header)"
# Every 15 minutes, 4 fires: up to an hour, plus the first wait and the last backup
LIMIT=$(((FIRES + 1) * 15 * 60 + 600))
START_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
read -r _ PG_BYTES0 < <(inventory pg pg-backups | awk -F'\t' '{n++; s += $2} END {print n + 0, s + 0}')
read -r _ MY_BYTES0 < <(inventory mysql mysql-backups | awk -F'\t' '{n++; s += $2} END {print n + 0, s + 0}')
echo "  store now: pg-backups $(mib "$PG_BYTES0"), mysql-backups $(mib "$MY_BYTES0")"
echo "  scheduled backups before this run (not judged): pg $(k -n "$NS" get backups.postgresql.cnpg.io -o name | grep -c '/pg-scheduled-'), mysql $(k -n "$NS" get perconaxtradbclusterbackups.pxc.percona.com -o name | grep -c '/cron-')"
echo "  watching for $FIRES fires each (up to $((LIMIT / 60)) min); polls every $POLL s"
echo

# pg_rows / my_rows: this run's scheduled backups, one per line
pg_rows() {
  k -n "$NS" get backups.postgresql.cnpg.io -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.creationTimestamp} {.status.phase} {.status.instanceID.podName} {.status.backupId} {.status.startedAt} {.status.stoppedAt}{"\n"}{end}' |
    awk -v t="$START_TS" '$1 ~ /^pg-scheduled-/ && $2 >= t'
}
my_rows() {
  k -n "$NS" get perconaxtradbclusterbackups.pxc.percona.com -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.creationTimestamp} {.status.state} {.status.destination} {.status.completed}{"\n"}{end}' |
    awk '$1 ~ /^cron-/'
}
secs() { python3 -c 'import datetime as d, sys; f = lambda s: d.datetime.fromisoformat(s.replace("Z", "+00:00")); print(int((f(sys.argv[2]) - f(sys.argv[1])).total_seconds()))' "$1" "$2"; }

declare -A PG_SEEN MY_SEEN MY_DEST MY_DONE
PG_DONE=0
MY_SUCC=0
MY_DELETED=0
OVER_KEEP=0 # consecutive polls with more than keep succeeded
OVER_MAX=0
T0=$SECONDS
while ((SECONDS - T0 < LIMIT)); do
  now="$(date -u +%H:%M:%S)"
  while read -r name created phase pod id started stopped; do
    [[ -n "$name" && "${PG_SEEN[$name]:-}" != "$phase" ]] || continue
    PG_SEEN[$name]="$phase"
    echo "  $now pg    $name: ${phase:-(no status yet)}${pod:+ from $pod}"
    if [[ "$phase" == completed ]]; then
      PG_DONE=$((PG_DONE + 1))
      read -r n b < <(inventory pg pg-backups | awk -F'\t' -v p="pg/base/$id/" 'index($1, p) == 1 {n++; s += $2} END {print n + 0, s + 0}')
      [[ "$pod" == "$(pg_primary)" ]] && where="the PRIMARY" || where="a replica"
      if ((n > 0)) && [[ "$where" == "a replica" ]]; then
        pass "pg $name completed from a replica, in the store" "$pod, $(secs "$started" "$stopped") s, $(mib "$b")"
      else
        fail "pg $name completed from a replica, in the store" "from $where ($pod), $n objects under pg/base/$id/"
      fi
    elif [[ "$phase" == failed ]]; then
      fail "pg $name completed" "failed (kubectl -n $NS describe backups.postgresql.cnpg.io $name)"
    fi
  done <<<"$(pg_rows)"

  ROWS="$(my_rows)"
  while read -r name created state dest completed; do
    [[ -n "$name" && "${MY_SEEN[$name]:-}" != "$state" ]] || continue
    [[ -z "${MY_SEEN[$name]:-}" && "$created" < "$START_TS" ]] && { MY_SEEN[$name]="$state"; continue; } # from before this run
    MY_SEEN[$name]="$state"
    echo "  $now mysql $name: ${state:-(no status yet)}"
    if [[ "$state" == Succeeded ]]; then
      MY_SUCC=$((MY_SUCC + 1))
      MY_DEST[$name]="${dest#s3://mysql-backups/}/"
      MY_DONE[$name]="$completed"
      read -r n b < <(inventory mysql mysql-backups | awk -F'\t' -v p="${MY_DEST[$name]}" 'index($1, p) == 1 {n++; s += $2} END {print n + 0, s + 0}')
      if ((n > 0)); then pass "mysql $name succeeded, in the store" "$(secs "$created" "$completed") s, $n objects, $(mib "$b")"; else
        fail "mysql $name succeeded, in the store" "no objects under ${MY_DEST[$name]}"; fi
    elif [[ "$state" == Failed || "$state" == Error ]]; then
      fail "mysql $name succeeded" "$state (kubectl -n $NS describe perconaxtradbclusterbackups.pxc.percona.com $name)"
    fi
  done <<<"$ROWS"
  # Deleted by retention: succeeded earlier in this run, now gone
  for name in "${!MY_DEST[@]}"; do
    grep -q "^$name " <<<"$ROWS" && continue
    prefix="${MY_DEST[$name]}"
    unset 'MY_DEST[$name]'
    MY_DELETED=$((MY_DELETED + 1))
    _gone() { [[ "$(inventory mysql mysql-backups | awk -F'\t' -v p="$prefix" 'index($1, p) == 1' | wc -l | tr -d ' ')" == 0 ]]; }
    echo "  $now mysql $name: deleted by retention; its files:"
    if wait_for 120 _gone; then pass "mysql $name deleted with its files" "s3://mysql-backups/$prefix empty"; else
      fail "mysql $name deleted with its files" "objects still under s3://mysql-backups/$prefix"; fi
  done
  # Never more than keep succeeded for long (the operator deletes after the newest succeeds)
  n_succ="$(awk '$3 == "Succeeded"' <<<"$ROWS" | grep -c .)"
  if ((n_succ > MY_KEEP)); then OVER_KEEP=$((OVER_KEEP + 1)); else OVER_KEEP=0; fi
  ((OVER_KEEP > OVER_MAX)) && OVER_MAX=$OVER_KEEP

  ((PG_DONE >= FIRES && MY_SUCC >= FIRES && MY_DELETED >= FIRES - MY_KEEP)) && break
  sleep "$POLL"
done

echo
echo "-- after $(((SECONDS - T0) / 60)) min --"
if ((PG_DONE >= FIRES)); then pass "pg: $FIRES scheduled backups completed" "$PG_DONE"; else fail "pg: $FIRES scheduled backups completed" "$PG_DONE"; fi
if ((MY_SUCC >= FIRES)); then pass "mysql: $FIRES scheduled backups succeeded" "$MY_SUCC"; else fail "mysql: $FIRES scheduled backups succeeded" "$MY_SUCC"; fi
if ((MY_DELETED >= FIRES - MY_KEEP)); then pass "mysql: the oldest beyond keep $MY_KEEP deleted" "$MY_DELETED"; else
  fail "mysql: the oldest beyond keep $MY_KEEP deleted" "$MY_DELETED of $((FIRES - MY_KEEP))"; fi
N_NOW="$(my_rows | awk '$3 == "Succeeded"' | grep -c .)"
if ((N_NOW == MY_KEEP)); then pass "mysql: exactly keep $MY_KEEP scheduled backups left" "$(my_rows | awk '$3 == "Succeeded" {printf "%s ", $1}')"; else
  fail "mysql: exactly keep $MY_KEEP scheduled backups left" "$N_NOW"; fi
if ((OVER_MAX * POLL <= 180)); then pass "mysql: more than keep for at most 3 min (the newest succeeds, then the oldest goes)" "$((OVER_MAX * POLL)) s at most"; else
  fail "mysql: more than keep for at most 3 min (the newest succeeds, then the oldest goes)" "$((OVER_MAX * POLL)) s"; fi
read -r _ PG_BYTES1 < <(inventory pg pg-backups | awk -F'\t' '{n++; s += $2} END {print n + 0, s + 0}')
read -r _ MY_BYTES1 < <(inventory mysql mysql-backups | awk -F'\t' '{n++; s += $2} END {print n + 0, s + 0}')
echo "  store: pg-backups $(mib "$PG_BYTES0") to $(mib "$PG_BYTES1") (kept 7 days); mysql-backups $(mib "$MY_BYTES0") to $(mib "$MY_BYTES1")"
echo
echo "  Now back to weekly (relational clusters root): terraform apply"
summary "scheduled backup checks"
