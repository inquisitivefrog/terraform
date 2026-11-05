# Runbook 22: replace a damaged node

**Purpose:** a member's disk is gone (or its host). Delete its pod and its
volume under load, let the operator build a fresh member from a healthy
peer, and prove there is no outage and no data loss. Measures the copy time
per GiB and latency while it runs.

**Run:** `relational/scripts/runbook_22_replace.sh pg|mysql [rate=20] [duration=10m] [dev]`.
Repeatable: the replacement is a full member under the same name (pg
1.30 rebuilds pg-1 as pg-1 on a new volume; the script also accepts a new
instance name).

## Preconditions

- Cluster whole; pick the member:
  - pg: a CloudNativePG replica. A damaged primary is runbook 24 first.
  - mysql: a Galera node HAProxy isn't sending writes to.
- Its data size, and more than twice that free on the nodes' disk.

## Steps and what each must show

1. k6 load starts (60 s to settle).
2. **Fence and destroy:** delete the member's volume (it waits for the pod
   to go), then the pod.
   - pg: what `kubectl cnpg destroy` does. CloudNativePG rebuilds the
     instance on a new volume and clones it from the **primary** with `pg_basebackup` (a
     join pod). CloudNativePG has no option to clone from a replica.
   - mysql: the StatefulSet recreates the pod with an empty volume. It joins
     by **SST** (xtrabackup) from a donor Galera picks. A donor is
     Donor/Desynced while it sends; if the donor is the writer, HAProxy
     may move writes away from it (reported).
   - A pod recreated while its old volume was still terminating would wait
     forever; the script deletes it again and counts it.
3. **Replaced and caught up** within **30 min**: old volume gone or
   replaced, writer unchanged, pg 2 replicas streaming / Galera 3 Synced.
   Copy time, per GiB, and the source.
4. **Latency:** create, search and read p95 from the app's histogram, the
   minute before against the rebuild.
5. What the app saw.
6. **No data lost:** after the load, the new member's fingerprint (rows,
   max id and checksum per table) equals the writer's.
7. `check_resources.sh` passes.

## Pass criteria

- **No write fails at all**; 0 lost.
- Reads may fail while the endpoint drops the member, but none from
  **30 s** after it is back (searches cancelled by the 5 s statement time
  limit excepted, counted; see the rules in README.md).
- Writer unchanged; the new member identical to the writer.
- `check_resources.sh` passes.

## Measured (lab, 2026-11-05, ~3,040,000 orders, 20 requests/s)

| | pg | mysql |
|---|---|---|
| Replaced | pg-1 (a replica), same name on a new volume | mysql-pxc-1 (a non-writer), same name on a new volume |
| Copy | pg_basebackup from the primary pg-3: 39 s for 561 MiB (71 s per GiB) | SST (xtrabackup) from donor pxc-2, not the writer: stream 17 s at 50.6 MiB/s; 66 s pod start to Synced for 1,519 MiB (44 s per GiB) |
| Destroy to whole | 73 s; 0 pods deleted again | 91 s; 0 pods deleted again |
| p95, minute before -> rebuild | create 3 -> 5 ms, search 79 -> 97 ms, read 1 -> 1 ms | create 8 -> 14 ms, search 810 -> 1,311 ms, read 3 -> 6 ms |
| Writes failed / lost | 0 / 0 (4,235 writes); reads failed 0 | 0 / 0 (4,278 writes); 2 searches failed during the rebuild, 0 after |
| Writer | unchanged (pg-3) | unchanged (pxc-0) |
| New member = writer | yes (fingerprints) | yes (fingerprints) |

A member's directory is mostly WAL: the old pg-1 held 1,297 MiB, the
clone 561 MiB (base 529, pg_wal 65); the primary keeps 721 MiB of WAL. So
the copy is the tables, not the whole directory. A first run the same
evening (the script then waited for a new instance name) took 140 s for the
same copy, 3.6x slower. Likely a cold cache: pg had no traffic for ~40
min before it (the lab runs load only inside a runbook), so the primary
read its files from disk; the second run came right after the first.

The mysql directory shrinks too (2,705 -> 1,519 MiB on the first rebuild):
the gcache (512M) and binlogs are not copied. A run at 22:22 failed on 3
searches cancelled by the 5 s statement time limit 4 min after the
rebuild (a burst of full-table scans; runbook 17's missing index); since
then such searches are counted, not judged (README.md).

Logs: `runbook-22-pg-20261105-214642.txt`, `runbook-22-mysql-20261105-224239.txt`.
