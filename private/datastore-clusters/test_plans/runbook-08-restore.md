# Runbook 8: restore into a new cluster

**Purpose:** prove a backup is real: restore it into a temporary fourth
cluster beside the live one (never over it), check the data is identical
and consistent and the app can use it, and time it (the realistic RTO).

**Run:** `relational/scripts/runbook_8_restore.sh pg|mysql [--keep] [dev]`.
Repeatable: the temporary cluster is deleted at the end (kept with `--keep`,
or when a step fails). Each run adds a backup to the store (step 1).

## Preconditions

- Cluster whole; `check_resources.sh` passes (66/66).
- No `<engine>-restore` cluster left from an earlier run.
- **Idle source:** no k6 load. The data is fingerprinted before and after
  the backup and the two must match.
- **3 GiB of the Docker VM's memory free** for the temporary database (the
  MySQL one is the source's size, 2 GiB, plus its restore Job). CPU to
  spare, as for runbook 7.

## Steps and what each must show

1. **Fingerprint, back up, fingerprint.** Per table: rows, highest id, and
   the sum of a hash of every row (pg `hashtext`, mysql `CRC32`). The
   backup is `backup_now.sh`. Both fingerprints match.
2. **Restore** into `<engine>-restore`, one instance, same image,
   resources and storage:
   - pg: a new Cluster with `bootstrap.recovery` from the store (the
     plugin, `serverName: pg`): the newest base backup, then the archived
     WAL. No `plugins` section, so it never archives into the source's path.
   - mysql: a one-node PXC cluster (`unsafeFlags`) with a copy of the live
     cluster's system passwords (`mysql.user` in the backup holds them),
     then a `PerconaXtraDBClusterRestore` with `backupSource` (the backup's
     destination, storage `s3`). No schedule, no binlog collector.
   Prints the time from creating it to ready.
3. **Consistency:** pg `bt_index_check(index, heapallindexed)` (amcheck)
   on every B-tree index, with data checksums on so every page read is
   verified; mysql `CHECK TABLE` on both tables.
4. **The restored fingerprint equals the source's.**
5. **The app can use it:** as the `app` user, over TLS, through the
   restored cluster's own endpoint (`pg-restore-rw`, `mysql-restore-haproxy`):
   the search query and an insert (rolled back).
6. Delete the restore cluster and its volumes; report anything left.
7. `check_resources.sh` passes.

## Pass criteria

- Identical fingerprints (source before = after backup = restored).
- No amcheck or CHECK TABLE errors.
- The app's read and write succeed.
- The live cluster is untouched; nothing of the restore cluster is left.
- Record: restore time (RTO for ~3,000,000 orders).

## Expected (lab, 2026-11-03)

| | pg | mysql |
|---|---|---|
| Backup (step 1) | 31 s, from pg-1, 185 MiB | 51 s, from a non-writer, 775 MiB |
| Restore time (create to ready) | **303 s** | **223 s**: empty cluster 61 s, then stopping 20 s, restoring 20 s, preparing 71 s, starting 41 s, ready 10 s |
| Consistency | amcheck: 5 B-tree indexes, no errors | CHECK TABLE: both OK |
| Rows compared | 3,022,030 (customers 10,000, orders 3,012,030), identical | 3,020,568 (customers 10,000, orders 3,010,568), identical |
| App read / write | 329 orders found; insert ok (rolled back) | 317 orders found; insert ok (rolled back) |
| Clean up | 10 s, nothing left | 20 s, nothing left |

Logs: see the rerun below (the first passes' logs were replaced).

**Rerun after moving the restore code into `runbook_lib.sh` (21:24-21:34,
HandBrake encoding on the Mac):** both pass. pg: backup 30 s, restore
**71 s** (so the first run's 303 s was a one-off, cause not found), 5
indexes clean, 3,022,584 rows identical. mysql: restore **213 s** (empty
cluster 51 s, operator 162 s), 3,022,290 rows identical. The mysql backup
took 175 s because its first Job pod failed: the transfer completed and
every chunk was uploaded, then `garbd` aborted while shutting down
("gcomm: terminating thread", exit 134, SIGABRT); the Job's retry
succeeded. Not found reported; seen once in five MySQL backups. Logs:
`runbook-8-pg-20261103-213148.txt`, `runbook-8-mysql-20261103-212410.txt`
(they replace the 19:12 and 19:26 ones).

**MySQL, first run (failed, fixed):** the restore with `backupSource`
`storageName: s3` failed at once: "nil s3 backup status storage". The CRD
accepts it but operator 1.20 wants the S3 settings inline
(`backupSource.s3`); the script now copies them from the live cluster's
storage.
