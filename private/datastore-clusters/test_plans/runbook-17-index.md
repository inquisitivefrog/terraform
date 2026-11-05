# Runbook 17: schema migration (add the missing index online)

**Purpose:** fix the planted slow search by adding an index under load,
without blocking writes, and prove the fix; then put the problem back so the
next run exercises the whole change.

**Run:** `relational/scripts/runbook_17_index.sh [--keep] pg|mysql [rate=20] [duration] [dev]`
(duration defaults: 4m pg, 15m mysql; `--keep` leaves the index: the real fix).

## The index

`orders_customer_created_idx` on `(customer_id, created_at, id)`. Each search
filters one customer and wants the newest 20, so the index walks that
customer's orders newest first and checks status on the way (about 1 in 5
match). It serves both search shapes; `(customer_id, status)` would serve only
one.

## Steps and what each must show

0. Preconditions; an index left by an earlier run is dropped first.
1. **Before:** both search plans scan the whole table (pg Parallel Seq Scan,
   mysql Table scan).
2. k6 load starts at 20 req/s (60 s to settle).
3. **Add the index without blocking writes:**
   - pg: `CREATE INDEX CONCURRENTLY`, `lock_timeout` 5 s; an INVALID index
     from a failed attempt is dropped and the build retried.
   - mysql: `pt-online-schema-change` (copy table in chunks behind triggers,
     pausing on Galera flow control, then swap). Not a plain ALTER: Galera
     runs DDL in total order and every node stops applying writes until it
     ends.
4. **No write failed and none lost** while it ran; the change finished before
   the load did.
5. **After:** the plans use the index on every node (pg Index Scan Backward
   using `orders_customer_created_idx`).
6. **Verify:** the load that failed before, **150 req/s for 5m**, meets every
   SLO.
7. **Restore** (unless `--keep`): drop the index on every node and confirm the
   plans scan again. Runs even when step 6 fails.

## Pass criteria

- 0 failed writes and 0 lost during the change.
- Index used on all 3 members.
- The 150 req/s run passes every k6 threshold (search p95 < 300 ms).
- Restore leaves the planted problem in place (plans scan again).

## Expected (lab, 2026-10-28, ~3,025,000 rows)

| | pg | mysql |
|---|---|---|
| Build | `CREATE INDEX CONCURRENTLY`, 2 s | pt-osc, 107 s (~1.6 min) |
| Writes failed / lost during the build | 0 / 0 | 0 / 0 |
| Search p95 during the change | 50 ms | 863 ms (the index arrives mid-run) |
| 150 req/s after: search p95 | 2.5 ms | 2.6 ms |
| 150 req/s after: failed | 0 of 45,002 | 0 of 45,002 |
| Plan time without the index | ~95–125 ms (Parallel Seq Scan) | ~650 ms (Table scan, 3 M rows) |

Rerun 2026-11-05 on `runbook_lib.sh` (~2,970,000 rows), both passed:

| | pg | mysql |
|---|---|---|
| Build | 4 s | pt-osc, **407 s** (3.8x 10-28's) |
| Writes failed / lost during the build | 0 / 0 (1,684 writes) | 0 / 0 (6,225 writes); 6 reads and searches failed (not judged) |
| p95 during the change | create 4.9 ms, search 53 ms | create **823 ms**, search 2.55 s (10-28: 19 ms, 863 ms) |
| 150 req/s after: search p95 | 3.1 ms | 4.3 ms |
| 150 req/s after: failed | 0 of 45,002 | 0 of 45,002 |
| Plan time without the index | ~205 / 73 ms | ~890 / 740 ms |

The mysql copy was CPU-bound: 6.0 of the Docker VM's 8 cores busy, each
reader node ~1.9 cores (applying the copy's write-sets while scanning for
searches), no flow control (pxc-2's receive queue peaked at 101). Why it
was 3.8x slower than on 10-28 is open; see the mysql slowdown after
runbook 16 in `private/docs/STATUS.md`.

A second mysql run failed: 4 of 6,389 writes timed out waiting for the
app's writer pool. A reader (also scanning for searches) fell ~170
write-sets behind, and Galera flow control paused every write for up to
half of each second; pt-osc's `--max-flow-ctl 0.5` (0.5% of time paused)
reacted only after the backlog was queued. pt-osc now sleeps 0.05 s after
each 0.1 s chunk (`--sleep 0.05`). Rerun 21:16, passed:

| mysql, `--sleep 0.05` | failed run | this run |
|---|---|---|
| Copy | 290 s | 297 s |
| Writes failed / lost | 4 / 0 of 6,389 | 0 / 0 of 6,297 |
| Flow control paused | up to ~50% | 0% (every node) |
| Max receive queue | ~170 | 13 |
| Writer threads running | 25 | 8 |
| p95 during the change | - | create 228 ms, search 1.76 s |
| 150 req/s after: search p95 | - | 4.4 ms, 0 of 45,002 failed |

The sleep cost almost nothing: the readers, not the copy, were the limit.

Logs: `runbook-17-pg-20261105-203120.txt`, `runbook-17-mysql-20261105-205530.txt`
(newest pass of each; the 407 s run's log was replaced).

## Caveats

- On `runbook_lib.sh` since 2026-11-05 (its own pg_psql and my_node stay:
  CONCURRENTLY can't run in a transaction; EXPLAIN ANALYZE needs raw output).
- Without the index, mysql search misses its SLO; every other runbook
  ignores search for that reason.
