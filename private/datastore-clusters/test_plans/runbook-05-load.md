# Runbook 5: load test (baseline)

**Purpose:** a repeatable load with fixed SLOs, used alone as a baseline and
before/after a change, and started in the background by every other runbook.

**Run:**
- `relational/scripts/load_test.sh pg|mysql run [rate=50] [duration=5m] [dev]`
- `relational/scripts/load_test.sh pg|mysql seed [orders=300000] [dev]` adds
  rows in bulk (the lab is seeded to ~3,000,000 per engine).

`K6_AVOID_ZONE=<zone>` keeps the k6 pod out of a zone (runbook 26).

## What it does

- A k6 Job in the cluster, next to the app; results stream into Prometheus
  (Grafana dashboard "Relational / Orders load", by `testid`).
- The mix: create 20%, read 45%, search 20%, update 10%, delete 5%, at a
  fixed arrival rate.
- Rows written by a run carry its id (`run_id` column).
- At the end k6 reads back the orders it created; any missing are counted in
  `orders_lost`.

## Pass criteria (k6 thresholds; exit non-zero if any fails)

| Operation | p95 | Failed |
|---|---|---|
| create | < 200 ms | < 1% |
| read | < 100 ms | < 1% |
| search | < 300 ms | < 1% |
| update | < 200 ms | < 1% |
| delete | < 200 ms | < 1% |
| `orders_lost` | — | 0 |

Each request times out at 15 s.

## Expected (lab)

- **pg, 20 req/s for 2m (2026-10-29):** passed. p95: create 3.6 ms, read
  1.0 ms, search 57 ms, update 2.6 ms, delete 2.3 ms; 0 of 2,402 failed.
  Log: `runbook-5-pg-20261029-223945.txt`.
- **pg, 150 req/s for 5m** (runbook 17's after-check, with the index):
  passed. p95 2–3 ms everywhere; 0 of 45,002 failed.
- **mysql, without the index:** fails the search threshold by design (search
  scans 3 million rows: p95 1.8 s or more at 20 req/s). That is the planted
  problem runbook 17 fixes.
- **mysql, 150 req/s for 5m with the index** (runbook 17): passed, p95 under
  4 ms everywhere, 0 failed.

## Caveats

- No standalone mysql baseline log is committed: the mysql run fails search
  by design until the index is added.
- The numbers are a laptop's; they're a regression baseline, not capacity.
