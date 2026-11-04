# Runbook 12: backup and archive storage check

**Purpose:** the backup store is healthy, has room to grow, keeps what
retention promises, and holds every log a restore needs. A backup that
"succeeded" is no use if the WAL or binlogs after it have a gap, or the disk
under the store fills.

**Run:** `relational/scripts/runbook_12_store.sh [dev]`. Read-only: it lists
the buckets (with the engines' own keys, handed to curl on stdin) and asks
the clusters. Safe under load. Weekly, and before relying on a backup.

## Checks and what each must show

The store (`datastore-backups`, SeaweedFS):
1. Running.
2. The Mac's free disk is at least 10 GiB and twice the store's size. The
   Docker VM's disk is a sparse file that grows into the Mac's free space
   (it reports 452 GiB; that is not the limit). Prints the store's size and
   its growth since the last passing run.
3. Each bucket's object count and size. Versioning: a **WARN**, not a fail,
   while it is off (no versioning means no object lock, so a stolen key can
   delete backups: the known gap from runbook 7).

PostgreSQL (`s3://pg-backups/pg/`):
4. Archiving is current: every WAL segment before the one being written is
   archived, and no failure since the last success (`pg_stat_archiver` on
   the primary). Not "archived in the last N minutes": an idle database
   switches no segment for hours.
5. Every base backup in the store: `backup.info` says `DONE` and it has data.
   Anything else is a **WARN** (a failed backup's leftovers).
6. At least one complete base backup; the oldest is within the 7-day
   recovery window plus one weekly cycle (else retention is not deleting).
7. WAL continuous from the oldest base backup's first segment to the last
   archived, by segment number on any timeline (a switchover continues the
   numbering on the next timeline). WAL older than the oldest base backup is
   a **WARN** (no restore can use it).
8. Prints the plugin's first recoverability point.

MySQL (`s3://mysql-backups/`):
9. The binlog collector (`mysql-pitr`) is ready and its last exit was not
   `OOMKilled`. Other restarts are a **WARN**: after a Docker restart it
   starts before MySQL is up, exits 1 ("can't find host") and is restarted
   until it connects (3 times on 2026-11-04).
10. Its memory peak (the pod cgroup's `memory.peak`, since the pod started)
    is under 90% of its limit. Each upload holds a 528 MiB buffer
    (docs/BACKUPS.md, "Its memory").
11. No `pitr-not-ready` marker (the operator would refuse point-in-time
    restores).
12. The uploaded binlogs' GTID sets join into one interval per server uuid,
    and reach what the cluster had executed when the check started (waits
    up to 150 s: the collector uploads every 60 s).
13. Every `Succeeded` backup has objects under its destination; full-backup
    prefixes with no backup resource are a **WARN** (orphans).
14. Scheduled backups (`cron-…`) number no more than keep (2).

## Pass criteria

- No FAIL. WARNs are listed for a person to decide; they need no action to
  pass.

## Expected (lab, 2026-11-03 22:06, MySQL under a 20 req/s load)

| Check | Result |
|---|---|
| Store | running; 1,786 MiB on disk; the Mac 17 GiB free |
| Buckets | pg-backups 30 objects, 577 MiB; mysql-backups 423 objects, 1,062 MiB; versioning off on both (WARN) |
| pg archiving | 0000000E…7D archived (2 hours earlier; idle), writing 7D: current |
| pg base backups | 3 complete (18:45, 19:12, 21:31, 185 MiB each); 20261102T203907 FAILED, backup.info only (WARN) |
| pg retention | oldest 0 days |
| pg WAL | 76 to 7D: 8 segments, none missing; 14 numbered before it (WARN; 6 of them on timelines 1-6, cause not yet found, see STATUS.md) |
| Collector | 0 restarts since 21:14; peak 1,159 of 1,536 MiB (75%; two buffers plus the process) |
| Binlogs | one interval 1-33553; current after 60 s; 33 files, 287 MiB |
| mysql full backups | mysql-manual-20261103-212415: 351 objects, 775 MiB; no orphans; 0 scheduled |
| Summary | 13 passed, 0 failed, 4 warnings |

## Caveats

- The collector's peak is since its container last started, so a restart
  resets it (109 MiB after the 2026-11-04 restart).
- Only the last exit is kept: an OOM kill followed by a startup exit would
  show as the startup exit. Check `kubectl describe` when restarts rise.
- A peak near the limit means the next upload can be OOMKilled (it was, at
  1Gi, on 2026-11-03): raise the limit or check upstream issue #2560.
- The collector never deletes binlogs from the store, and the operator only
  deletes full backups. Binlog growth is unbounded until cleaned by hand
  (about 287 MiB after a day of lab loads).
- Continuity is checked from the oldest base backup only. A gap before it
  costs nothing; a gap after it breaks every restore to a time past the
  gap.
- Object lock is not tested, because it is off. On AWS (S3 Object Lock,
  compliance mode) this check would read the bucket's lock configuration
  instead.
