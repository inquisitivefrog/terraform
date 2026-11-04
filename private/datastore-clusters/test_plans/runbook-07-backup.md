# Runbook 7: back up

**Purpose:** a full backup of each engine, taken by hand, lands in the
backup store outside the cluster, while the cluster keeps serving. The
weekly schedule and the continuous log archiving are configuration
(`relational/scripts/check_resources.sh`, "backups"); this is the on-demand
backup the runbooks take before a change.

**Run:** `relational/scripts/backup_now.sh pg|mysql [dev]`. Adds a backup to
the store each time (it stays until deleted; see the script's header).

## Preconditions

- The backup store is running (`platform/scripts/check_resources.sh`: the
  backup store section passes); `check_resources.sh` passes (66/66).
- **CPU to spare.** On 2026-11-02 the Mac was encoding video (HandBrake,
  ffmpeg), the Docker VM got about 2.4 of its 8 CPUs, and the first pg
  backup failed after 22 minutes while MySQL collapsed (see STATUS.md).

## Steps and what each must show

1. The store's size before.
2. Create the backup resource:
   - pg: a `Backup` with `method: plugin`, `target: prefer-standby`: the
     Barman Cloud plugin copies a replica's data files.
   - mysql: a `PerconaXtraDBClusterBackup`: a Job joins Galera as an
     arbitrator, a non-writer node donates a copy with XtraBackup, the Job
     uploads it.
3. It completes (pg `completed`, mysql `Succeeded`) within 30 minutes.
4. Its location is in the status and the store has objects there.

## Pass criteria

- Completed; objects in the store under the backup's own prefix.
- Taken from a replica (pg) or a non-writer (mysql), never the writer.
- The cluster stays whole.

## Expected (lab, 2026-11-03, HandBrake still running)

| | pg | mysql |
|---|---|---|
| Copied from | pg-1 (replica) | mysql-pxc-2 (donor; writer pxc-0) |
| Time | 51 s | 71 s (donor desynced 32 s) |
| Size in the store | 185 MiB, 2 objects (bzip2) | 775 MiB, 351 objects (uncompressed) |
| Where | `s3://pg-backups/pg/base/<id>/` | `s3://mysql-backups/mysql-<date>-<time>-full/` |

Logs: `backup-pg-20261103-184539.txt`, `backup-mysql-20261103-184711.txt`.

## The schedule and retention (`runbook_7_schedule.sh`)

The weekly schedule never fires during a session, so a short one is applied
for the test and removed after (relational clusters root):

```
terraform apply -var 'pg_backup_schedule=0 */15 * * * *' -var 'mysql_backup_schedule=*/15 * * * *'
relational/scripts/runbook_7_schedule.sh      # about an hour, 4 fires each
terraform apply                               # back to weekly
```

It only watches. While the short schedule is applied, `check_resources.sh`
fails its two schedule checks, by design.

Pass:
- pg: each fire's Backup completes, from a replica, files in the store.
- mysql: each fire's backup succeeds; once more than keep (2) have
  succeeded the oldest is deleted, files included, within 3 minutes; at the
  end exactly 2 are left. Backups by hand are not counted.
- pg retention (a 7-day recovery window) can't be seen in an hour; those
  backups stay until it passes (about 185 MiB each).

Seen on applying (2026-11-04): CloudNativePG ran one backup at once for the
missed slot, named after it (`pg-scheduled-20261102190000`), then kept to
the schedule (next 18:30). Not a catch-up of every missed slot.

Expected (lab, 2026-11-04 18:28-19:16, `runbook-7-schedule-20261104-182848.txt`):
15 passed.

| Fire | pg (from pg-1, 185 MiB) | mysql (775 MiB) | Deleted by keep 2 |
|---|---|---|---|
| 18:30 | 24 s | 50 s | |
| 18:45 | 63 s | 69 s | |
| 19:00 | 24 s | 113 s | 18:30, files gone in the same poll |
| 19:15 | 24 s | 32 s | 18:45, same |

Never more than 2 scheduled MySQL backups at a poll (30 s): the operator
deletes the oldest as the newest succeeds. Store: pg 762 to 1,503 MiB (kept
7 days), mysql 1,072 to 2,622 MiB. The user applied the clusters root
without the short schedule once mid-run (18:37); re-applied 18:41, before the next fire: none
missed.

## The alerts (docs/BACKUPS.md, "Alerts")

1. Platform services root first (kube-state-metrics' PXC backup metrics,
   the alert-log receiver): platform check passes, Alertmanager sends to
   alert-log. Then the relational clusters root (the rules). Applied the
   other way round, MySQLBackupTooOld fires until the metric exists.
2. Relational check: the backup metrics exist, 7 backup rules loaded, none
   firing.
3. Lower the threshold: `terraform apply -var backup_alert_after_hours=0.1`
   (with the weekly schedule, so no new backup resets the age), then
   `relational/scripts/runbook_7_alerts.sh fire`: within about 16 minutes
   of the newest backups, PostgreSQLBackupTooOld and MySQLBackupTooOld are
   firing in Prometheus, held by Alertmanager, and alert-log prints a
   `firing` line for each; no other backup alert fires.
4. `terraform apply` without it, then `runbook_7_alerts.sh resolve`: both
   stop firing and alert-log prints `resolved` for each (Alertmanager sends
   it at the next group interval, up to 5 minutes).

Expected (lab, 2026-11-04):

| | PostgreSQLBackupTooOld | MySQLBackupTooOld |
|---|---|---|
| fire (`runbook-7-alerts-fire-20261104-193842.txt`) | firing 19:44:43; alert-log `relational/pg` 20 s later | firing 19:44:35; alert-log `relational/mysql` |
| resolve (`runbook-7-alerts-resolve-20261104-194939.txt`) | cleared within 10 s of the rules loading; `resolved` 20 s later | same |

Found on the way:
- The first rules had no `namespace` label (`max()` drops every label), so
  alert-log printed `-/pg` and the script matched nothing; Alertmanager also
  put them in a group of their own. Fixed: the backup rules carry
  `namespace` themselves.
- Prometheus loads changed rules up to a minute after an apply; the script
  waits up to 2 minutes for the threshold it expects.

