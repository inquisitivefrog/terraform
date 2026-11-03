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
  backup store section passes); `check_resources.sh` passes (63/63).
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
