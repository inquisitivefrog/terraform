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
  backup store section passes, 42/42); `check_resources.sh` passes (68/68).
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


## Under load

A 10-minute load at 20 requests/s (`load_test.sh <engine> run 20 10m`),
with `backup_now.sh <engine>` started 2 minutes in. Passes when the backup
completes and k6 loses no order, with write and read latency as without a
backup.

Expected (lab, 2026-11-04):

| | pg | mysql |
|---|---|---|
| backup | 31 s, 185 MiB, from replica pg-1 | 51 s, 776 MiB |
| k6 | passed; 0 of 12,001 failed; p95 create 3.7 ms, read 1.3, update 3.0, delete 2.5, search 58 ms | search over its SLO only (p95 1.07 s: the runbook 17 missing index, 0.8-1.1 s in every MySQL load), 1 search failed of 11,995; p95 create 10.9 ms, read 3.4, update 10.1, delete 10.5 |
| orders lost | 0 | 0 |

## Over TLS, encrypted at rest

After `backup_store_tls.sh`, `backup_store_buckets.sh` and the applies
(docs/BACKUPS.md, "Encryption"):

1. Platform `check_resources.sh`: the store refuses plain http, its
   certificate checks against our CA, both buckets encrypt by default, the
   encryption key comes from `security.toml` (36/36).
2. Relational `check_resources.sh`: both clients point at https with the
   CA Secret (68/68).
3. `backup_now.sh pg` and `backup_now.sh mysql` pass.
4. The new objects are `SSE_S3` in the store's metadata (`fs.meta.cat`,
   BACKUPS.md), on both engines; objects from before stay plain.

Expected (lab, 2026-11-04): all four. pg 30 s, 185 MiB; mysql 41 s and
40 s, 775 MiB. The binlog collector resumed from its last upload. Two
clients stuck during the switch (BACKUPS.md, "Turning TLS on in a running
lab"): the collector and the old pg primary, each fixed by recreating it.

## Object lock (`runbook_7_lock.sh`)

After `backup_store_buckets.sh` (lock on; `--lock-days 1` while testing)
and a backup of each engine:

1. `runbook_7_lock.sh check`: both buckets COMPLIANCE with versioning; the
   newest pg base backup and MySQL full backup locked; per bucket, a canary
   written with the engine key is locked as written; a delete only hides it
   (204, then 404) and its version stays; deleting the version is refused
   with the engine key, the admin key and the governance bypass (403);
   shortening the lock is refused (403); the version reads back unchanged;
   removing the delete marker brings it back; an overwrite adds a version
   and keeps the original; suspending versioning is refused (409).
2. After the lock days, daily: `runbook_7_lock.sh expire`: the replaced
   version is gone by itself within a day of its lock (the lifecycle rule;
   fails at 2 days); then the current one is deletable (204).
3. Then `backup_store_buckets.sh` without `--lock-days`: back to 7 days.

Expected (lab, 2026-11-04, 1 day): check 38/38; backups pg 31 s, mysql
41 s, both locked until the next day; platform 42/42, relational 68/68.
Expire: 2026-11-05 23:02 not finished (replaced versions past their lock
at 22:56, waiting for the lifecycle rule); **2026-11-06 23:16 pass**, 4/4:
both replaced versions removed by the store, both canaries deletable
(204), within a day of the lock ending. Then `backup_store_buckets.sh`:
both buckets COMPLIANCE 7 days.
