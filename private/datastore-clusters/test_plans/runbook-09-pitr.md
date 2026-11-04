# Runbook 9: point-in-time recovery

**Purpose:** recover from a bad `DELETE`: restore to just before it into a
new cluster, prove the lost rows are there and the mistake is not, copy
them back into the live cluster, and time it.

**Run:** `relational/scripts/runbook_9_pitr.sh pg|mysql [--keep] [rate=20] [duration=3m] [dev]`.
Repeatable: the live cluster ends where it started and the recovery
cluster is deleted (kept with `--keep`, or when a step fails).

## Preconditions

- Cluster whole; `check_resources.sh` passes (66/66).
- A full backup in the store (`backup_now.sh`); for mysql the binlog
  collector ready.
- No `<engine>-recovered` cluster left over; no other k6 load; 3 GiB of the
  Docker VM's memory free; CPU to spare (as for runbook 7).

## Steps and what each must show

1. **Writes after the backup:** a k6 run (its SLO is not judged here). Its
   orders exist only in the archived WAL / binlogs, so the recovery must
   replay them.
2. **The good state:** fingerprint (per table: rows, highest id, a sum of a
   hash of every row) twice, 5 s apart: equal (idle). Count the run's
   orders.
3. **The mistake:** note the server's time T; `DELETE` every order of the
   run on the writer. Deleted = counted.
4. **The logs past T are in the store:** pg switches WAL and waits until
   the new file is archived; mysql waits until an uploaded binlog's GTID
   set (`binlog_*-gtid-set` in the bucket) covers the last transaction
   before T.
5. **Recover to T** into `<engine>-recovered`, one instance:
   - pg: `bootstrap.recovery.recoveryTarget.targetTime` T (microseconds).
   - mysql: `PerconaXtraDBClusterRestore` of the newest full backup with
     `pitr: {type: date, date: T}`. Whole seconds, so T is the next whole
     second after the good state, and the DELETE is 3 s later.
   Prints the time from create to ready.
6. **Consistent** (amcheck / CHECK TABLE) and **its fingerprint equals the
   good state's**: the deleted orders are there, the DELETE is not.
7. **Copy the run's orders back** into the live cluster (pg: `\copy`
   through a temporary table, `OVERRIDING SYSTEM VALUE` for the identity
   ids; mysql: `mysqldump --where` into the writer). The live fingerprint
   equals the good state's again.
8. Delete `<engine>-recovered`; report anything left.
9. `check_resources.sh` passes.

## Pass criteria

- Recovered fingerprint = good state (every row, ids included).
- Copied back = deleted; live fingerprint = good state.
- No consistency errors; nothing of the recovery cluster left.
- Record: the recovery time.

## Caveats

- The database is idle at T, so the comparison is exact. Under load, a
  time target splits transactions at T (MySQL to the second); a real
  recovery reconciles the rows written after T, or uses a GTID or a
  transaction id as the target.
- T is known because the script made the mistake. For a real one, find it
  in the logs: the app's, the database's, or the WAL / binlog themselves
  (`pg_waldump`, `mysqlbinlog`).
- The operator refuses a MySQL point-in-time restore when the collector has
  marked a gap (`pitr-not-ready` in the store) unless the restore carries
  `percona.com/unsafe-pitr`; the script never sets it. None seen
  2026-11-03.

## Expected (lab, 2026-11-03)

| | pg | mysql |
|---|---|---|
| Load (step 1) | 20 req/s for 3m: 751 created, 197 deleted by k6, 0 failed | 20 req/s for 3m: 753 created, 176 deleted, 0 failed (search SLO missed by design) |
| Orders of the run deleted (the mistake) | 554 | 577 |
| Logs past T in the store | 10 s (WAL switch, archived) | 1 s (a binlog covering GTID 30689 uploaded) |
| Recovery time (create to ready) | **71 s** (base backup pg-manual-20261103-191252 plus WAL) | **243 s**: empty cluster 50 s; stopping 21 s, restoring 20 s, preparing 112 s, point-in-time recovering 10 s, starting 10 s; ready 20 s (earlier runs with HandBrake encoding: 439 s, 400 s) |
| Consistency | amcheck: 5 B-tree indexes, no errors | CHECK TABLE: both OK |
| Recovered = good state | yes (3,022,584 rows) | yes (3,022,290 rows) |
| Copied back / live = good state | 554 / yes | 577 / yes |
| Clean up | 10 s, nothing left | 20 s, nothing left |

Logs: `runbook-9-pg-20261103-195215.txt`, `runbook-9-mysql-20261103-211514.txt` (the first with the binlog collector at 1.5 Gi: 0 restarts, peak 660 MiB).

**MySQL, first run (20:19):** steps 0-7 passed, then the cleanup check failed:
the recovery cluster was named `mysql-pitr`, the same as the live
cluster's binlog collector Deployment, and the check (by name) kept seeing
the collector's pod. The recovery cluster was in fact gone. Fixed: the
target is now `<engine>-recovered`, and the check selects by label. Log
(failed, not committed, replaced by the pass).

Open question: runbook 8's restore of a similar base backup took 303 s
(19:12) against 71 s here; to look at with runbook 8's rerun.
