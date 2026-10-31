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

Logs: `runbook-17-pg-20261028-224134.txt`, `runbook-17-mysql-20261028-215757.txt`.

## Caveats

- Runbook 17 predates `runbook_lib.sh`; moving it onto the library is open.
- Without the index, mysql search misses its SLO; every other runbook
  ignores search for that reason.
