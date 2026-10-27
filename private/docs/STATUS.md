# private: status

Rolling record for the private cloud (Docker Desktop + kind on the laptop).
Newest first.

## Current state (2026-10-27): platform, relational and the orders app applied

kind cluster `datastore-dev` (4 nodes, zones dc1-a/b/c) with
kube-prometheus-stack; CloudNativePG and Percona PXC operators; `pg`
(PostgreSQL 16.13, 3 instances) and `mysql` (PXC 8.0.44, 3 nodes + 3
HAProxies) in namespace `relational`, both scraped by Prometheus with
dashboards in Grafana. Verified: platform check 13/13 (including
monitoring), relational check 35/35 before the app. Disk blocker cleared (65 GB free); Docker
Desktop at 14 GB memory, 8 CPUs.

2026-10-27: the orders app (`orders:0.1.2`, Spring Boot) runs against both
clusters, two pods each, with k6 load and a Grafana dashboard. Both engines
hold about 3 million orders. PXC nodes at 1536Mi; PostgreSQL
`hot_standby_feedback` on. Checks: platform 13/13, relational 45/45, also
after a full Docker Desktop shutdown and restart. Search fails its SLO by
design (the planted missing index, runbook 17).

## 2026-10-27: PostgreSQL at 150 requests/s; orders 0.1.2 (no retries on a statement timeout)

- **Run:** `load_test.sh pg run 150 5m` at 3 million orders: FAILED, search only.
  - Search p95 6.08 s (max 12.33 s), 33% errors; read 11.9 ms, create 43.5 ms, update 38.8 ms, delete 33.3 ms p95; lost writes 0.
  - All 2,981 errors were reader-pool acquire timeouts (up to 78 waiting). The replicas did the scans (pg-3 3.6 cores, pg-1 2.9) while the primary pg-2 used 0.05: PostgreSQL's parallel scans on the replicas kept writes isolated.
  - **573 search retries remained** in 0.1.1. Spring translates PostgreSQL's `57014` (statement timeout) into `QueryTimeoutException`, a `TransientDataAccessException`, so each 5 s timeout ran again (the 12.3 s maximum).
- **The fix (0.1.2):** `Retrier` never retries a statement timeout: `QueryTimeoutException`, SQLState `57014`, or MySQL error 3024 (`max_execution_time`). MySQL's 3024 was not being retried under 0.1.1 (Spring leaves it uncategorized); its exclusion is defensive.
  - Test `doesNotRetryAStatementTimeout` uses Spring's real PostgreSQL translator; the suite passes 13/13. Image `orders:0.1.2` is loaded into the nodes; the `app_image` default is now `orders:0.1.2`.
- **To verify:** apply the app root, then rerun `load_test.sh pg run 150 5m`. Expect 0 search retries and a search maximum of about 8 s (3 s acquire plus 5 s statement).
- **Still to exercise before committing:** `docker_shutdown.sh` without `--keep-docker`.

## 2026-10-27: full shutdown and restart; orders-mysql truststore crash loop

- **`docker_shutdown.sh` without `--keep-docker`: passed.** Workers stopped first, then the control plane; Docker Desktop quit and freed its memory. Exit 130 from the kind nodes is their normal stop.
- **`docker_restart.sh`: found a bug.**
  - Docker, the API, the nodes, Galera, the PXC operator, PostgreSQL streaming and Prometheus all came back. Relational checks 41/45, platform checks 12/13.
  - Both `orders-mysql` pods stayed in `Init:CrashLoopBackOff` ("every pod ready" gave up after 600 s). The 2 scrape targets down were those pods.
  - **Cause:** the `truststore` init container ran `keytool -importcert` again into the same emptyDir, which survives a node restart because the pod is the same one. keytool refused: `alias <cluster-ca> already exists`. The restart cycles earlier today were before the app existed.
- **Fix (orders-app module):** the init container deletes the `cluster-ca` alias, then imports. It replaces the entry rather than skipping it, so a rotated CA is picked up.
  - Tested in the `orders:0.1.2` image with a scratch CA. The old command fails on its second run. The new one passes a first start (no store), a restart, and a CA swap (CN=rotated to CN=third, 1 entry).
- **Verified:** the app root applied (only `orders-mysql` changed), checks 45/45. A second `docker_shutdown.sh` and `docker_restart.sh` then gave platform 13/13 (37 targets up, 0 down) and relational 45/45. `orders-mysql` came back without a crash loop.
- **One more restart-script bug:** "Every pod restarted and ready" still gave up after 600 s with everything healthy. It skipped finished Job pods only if they `Succeeded`; a k6 run that misses its SLO leaves a `Failed` pod, never ready.
  - Fix: `pods_fresh` skips `Failed` pods too. A crash-looping pod is still `Running`, so it is still caught.
  - Checked against the live cluster with the restart's start time (22:39:20): the old function fails and the new one passes.
- **Verified by a third full cycle:** `docker_shutdown.sh`, then `docker_restart.sh`. Every pod was ready in 200 s (the k6 Job pods skipped); platform 13/13, relational 45/45. Every path from today has now run.

## 2026-10-27: hot_standby_feedback on, verified at 150 requests/s

- **Applied:** clusters root, `hot_standby_feedback = "on"` (in-place change to the `pg` Cluster). Reloaded on all three instances; no restart (postmasters still from 18:41). Checks 45/45.
- **Run `pg-run-20261027-215852`, 150 requests/s for 5 m, 3 million orders:** FAILED, search only, as expected: the missing index.

  | | before (21:41) | after (21:58) |
  |---|---|---|
  | Recovery conflicts (pg-1 / pg-3) | 1,102 / 1,021 | +0 / +0 |
  | Replica lag, max | 22 s | 0 s |
  | App `EOFException`s | ~500 | 0 |
  | Search retries | 498 | 0 |
  | Search p95 / max | 6.13 s / 11.83 s | 4.43 s / 5.06 s |
  | Search errors (reader-pool 503) | 29.9% | 26.9% |
  | Reader pool max waiting per pod | 77 | 52 |
  | create / read / update p95 | 40 / 18 / 36 ms | 60 / 30 / 58 ms |
  | Lost writes | 0 | 0 |

- **The cost of the setting:** 10,543 dead rows in `orders` on the primary (0.35% of 3.03 million) after the run. Autovacuum did not need to run.
- **Retry fixes done:** no retries on a full pool (0.1.1), a statement timeout (0.1.2) or, now, a recovery conflict. The worst search now takes at most one statement timeout (5 s).
- **Still failing, by design:** search scans on the replicas, at 3.1 and 3.8 cores on pg-3 and pg-1; the primary uses 0.06. Runbook 17 (the index) is the fix.
- **Still to exercise before committing:** `docker_shutdown.sh` without `--keep-docker`.

## 2026-10-27: orders 0.1.2 applied; 150 requests/s exposed replica recovery conflicts

- **Applied:** both apps on `orders:0.1.2` (pods started 21:40 UTC); checks 45/45.
- **Run `pg-run-20261027-214159`, 150 requests/s for 5 m:** FAILED, search only, as before.
  - Search p95 6.13 s (max 11.83 s), 29.9% errors (all reader-pool 503s, up to 77 waiting per pod).
  - Other operations p95: read 18 ms, create 40 ms, update 36 ms, delete 32 ms.
  - Lost writes 0; 170 dropped iterations.
- **No statement timeout was retried: the 0.1.2 fix holds.** But 498 search retries remained. Searches that succeeded after a retry took up to 11.8 s.
- **The cause: hot-standby recovery conflicts.** The app logged ~500 `EOFException`s ("An I/O error occurred while sending to the backend").
  - pg-1 and pg-3 logged ~580 `canceling statement due to conflict with recovery` and ~500 `terminating connection due to conflict with recovery` (FATAL, so the client sees EOF).
  - `pg_stat_database_conflicts`: 1,102 snapshot conflicts on pg-1. Replica lag reached 22 s.
  - With `hot_standby_feedback` off, vacuum on the primary removes rows the replicas' 3-5 s scans still read. Back-to-back scans keep replay waiting until `max_standby_streaming_delay` (30 s) is spent; after that, every conflicting query is cancelled at once.
  - Retrying a terminated connection is correct (it looks like a failover); the fault is the server setting.
- **The fix, to apply:** `hot_standby_feedback = "on"` in the clusters root's PostgreSQL parameters. CloudNativePG reloads it; no restart. Runbook 29 has the engine note.
- **To verify:** apply the clusters root and rerun `load_test.sh pg run 150 5m`. Expect 0 recovery conflicts (`pg_stat_database_conflicts` unchanged), replica lag under a second, and search retries near 0.

## 2026-10-27: orders 0.1.1 applied and verified (runbook 40, shed-load step)

- **Applied:** both apps on `orders:0.1.1` (pods started 21:09 UTC); checks 45/45.
  - The node's containerd shows `sha256:e0c7…`, not Docker's `26c4…`. That is the config digest against Docker Desktop's index digest; 0.1.0 showed the same pattern. The behaviour below proves the new code is running.
- **MySQL at 3 million orders, 50 requests/s for 5 m, 0.1.0 against 0.1.1** (Prometheus over each run's 5 minutes):

  | | 0.1.0 | 0.1.1 |
  |---|---|---|
  | Search retries | 2,915 | 0 |
  | Max waiting, reader / writer pool | 45 / 10 | 21 / 3 |
  | Search p95 / max | 14.2 s / 17.4 s | 6.8 s / 8.3 s |
  | Search errors (503) | 12.4% | 23.8% |
  | create / read / update p95 | 911 / 497 / 844 ms | 831 / 467 / 764 ms |
  | Lost writes | 0 | 0 |

- **The trade-off was intended:** fail fast instead of queueing. Errors doubled while latency halved, and the writer pool waits less.
  - Of the errors, 688 were reader-pool acquire timeouts (503) and 35 hit MySQL's 5 s `max_execution_time`.
  - The SLO still fails: the cause, the missing index, is runbook 17's to fix, after which pool waits should drop to zero (runbook 40's full Verify).
- **Still to exercise before committing:** `load_test.sh pg run 150 5m` and `docker_shutdown.sh` without `--keep-docker`.

## 2026-10-27: orders 0.1.1 (no retries on a full pool); runbook 40 added

- **The fix:** `Retrier` no longer retries a HikariCP acquire timeout that has no underlying connection failure. A full pool is overload: the request gets a 503 at once.
  - A timeout with a cause (the database unreachable, e.g. a failover) still retries.
  - Checked against HikariCP 7.0.2: `createTimeoutException` attaches `getLastConnectionFailure()` as the cause.
- **Tests:** a new `RetrierTest` (4 tests); the full suite of 12 passes.
- **Release:** image `orders:0.1.1` loaded into the kind nodes; the app root's default image is now 0.1.1.
- **Runbooks: 40.** New: 40, connection pool saturation (client side), the counterpart of 32 (server-side `max_connections`). It is numbered last so existing references stay valid, and listed next to 32. Counts updated in RUNBOOKS.md, DESIGN.md and README; a row added to "common problems".

## 2026-10-27: PXC at 1536 Mi; MySQL at 3 million orders fails the SLO everywhere (the runbook 2 "before")

- **Applied:**
  - PXC memory 768 Mi → 1536 Mi: SmartUpdate rolled the nodes one at a time and the apply waited (4 m). Buffer pool now 768 MiB.
  - k6 seed thresholds.
  - Checks: 45/45.
- **Seed to 3,000,436 orders:** 1,620,000 in 26 s, every batch succeeded. Peak PXC RSS 966–1131 MiB of 1536 (the old limit would have been exceeded again).
- **Run at 50 requests/s for 5 m: FAILED.** 6 thresholds crossed. `load_test.sh` reported it and exited 1, which exercised the failure branch on a real failure.

  | Operation | p95 | SLO | Errors |
  |---|---|---|---|
  | read | 497 ms | 100 ms | 0% |
  | create | 911 ms | 200 ms | 0% |
  | update | 844 ms | 200 ms | 0% |
  | delete | 684 ms | 200 ms | 0% |
  | search | 14.2 s (max 17.4 s) | 300 ms | 12.4% (364 of 2,934) |

  Other run results: lost writes 0; 135 dropped iterations; up to 121 virtual users busy.
- **Why every operation slowed, unlike PostgreSQL:**
  - *No isolated reader.* Percona's `mysql-haproxy-replicas` balances over all three nodes, the writer included (the check "Reader endpoint answers: mysql-pxc-0" showed it). The writer ran 10 concurrent full-table scans and its point reads and writes queued behind them.
  - *Replicas fell behind and paused the cluster.* The other nodes, also scanning, applied write sets late (receive queues averaged 47 and 91), and pxc-2 sent flow control 113 times, pausing writes cluster-wide.
  - *No parallel scan.* A MySQL scan is single-threaded; PostgreSQL split each search over 3 workers on a replica and left the primary alone.

  The planted problem and the data are the same as on PostgreSQL, but the blast radius is far larger.
- **Search errors were mostly the app, not MySQL:**
  - Only 11 searches hit MySQL's 5 s `max_execution_time`.
  - About 350 waited 3 s for a reader-pool connection (10 of 10 busy, up to 45 waiting per pod).
  - The app's `Retrier` treats pool exhaustion as transient and retried each up to 4 times: 2,924 retries, and latencies of 12–17 s.
  - Retrying a full pool adds load and queueing instead of shedding it: the retry-storm pattern of runbook 32, built into the app. To fix: retry only when a connection failed (failover), not when the pool is merely full.

## 2026-10-27: MySQL load runs; a PXC node OOMKilled under the bulk seed (runbook 34, for real)

- **The first runs passed.** MySQL seed, 300,000 orders: 7 s, 0 failures. Run at 50/s for 5 m:

  | Operation | p95 |
  |---|---|
  | read | 1.5 ms |
  | create | 4.4 ms |
  | update | 4.3 ms |
  | delete | 3.5 ms |
  | search | 59 ms |

  0 errors in 15,002 requests and 0 lost writes. At this size MySQL's search is already 5 times PostgreSQL's (one thread scanning, no parallel workers).
- **Seeding 2.7 million more failed** (20:33:56–20:36:26): 164 of 270 batches failed after 3 s, the app's connection timeout. `load_test.sh` still printed "passed": seed mode had no thresholds, so k6 exited 0.
- **`mysql-pxc-1` OOMKilled at 20:36:55** at its 768 Mi limit. Prometheus showed a steady-state RSS of 610–690 MiB, with the buffer pool at 384 MiB (the operator gives it half), and a peak of 743 MiB under the 4 parallel seeders plus 42 connections. The other nodes left the Primary Component.
- **The run started at 20:36:54 hit a dead cluster.** Both app pods crash-looped, because Flyway can't connect at startup. k6 hit its 200-user limit within seconds, then got EOF and "connection refused" (no pods behind the Service). The Job ended Failed, which exercised `load_test.sh`'s FAILED branch.
- **Recovery took 8 minutes, with no intervention** (20:36:55 to 20:44:53). pxc-1 bootstrapped alone at seqno 6700; pxc-0 and pxc-2 went through `--wsrep-recover` and crash-loop back-off, then rejoined (each node "3 Synced"). The app pods restarted by themselves.
- **Rows in `appdb.orders`:** 1,380,262 (1,378,000 seeded).
- **Fixes, not yet applied:**
  - PXC memory raised to 1536 Mi (clusters root; the operator sizes the buffer pool at about 768 MiB, leaving about 700 MiB headroom; about 2.3 GB more of the VM);
  - the k6 seed now has `checks rate==1` with `abortOnFail`, so a failing seed stops at its first bad batch and the script reports FAILED.
- **Lesson:** 768 Mi was sized before any load. The request = limit rule was kept but the size was a guess, and steady-state headroom was 10–20%. Size from a measured peak under load, not from idle.

## 2026-10-27: first load runs on PostgreSQL (the runbook 2 "before")

Checks after the replacement apply: 45/45 (the app zone check now selects app pods only, not the k6 Job pods that share their instance label).

k6 at 50 requests/s for 5 minutes against `orders-pg`, using the mix create 20 / read 45 / search 20 / update 10 / delete 5:

| Orders in table | read p95 | create p95 | update p95 | delete p95 | search p95 | Errors | Lost writes |
|---|---|---|---|---|---|---|---|
| 300,000 (heap 30 MB) | 1.3 ms | 3.1 ms | 2.8 ms | 2.2 ms | 11.3 ms | 0 / 15,001 | 0 |
| 3,000,000 (heap 301 MB) | 1.3 ms | 4.0 ms | 3.3 ms | 3.0 ms | 93.3 ms (max 436 ms) | 0 / 15,002 | 0 |

- **Every SLO passed in both runs.** The planted missing index made search 8 times slower while reads stayed flat. The heap now exceeds `shared_buffers` (128 MB) and each search is a parallel sequential scan over the whole table; at 300,000 rows the same plan took 8 ms from memory.
- **Seeding speed:** 300,000 orders in 2 s; 2,700,000 more in 22 s.
- **Searches mostly hit one replica.** Searches go to `pg-ro`, but nearly all ran on one replica (`pg-1` at 1.55 cores, `pg-3` near idle), although app connections were spread evenly (11 and 13). The Service balances connections, not queries, and HikariCP reuses its most recently used connection, so at low concurrency each pod's busy connections stay on one replica. Left in place deliberately: it matters for runbook 2 (one hot replica) and runbook 25 (losing it moves all search load at once). Possible fixes are connection max lifetime, a pooler, or per-query balancing.

## 2026-10-27: orders app applied; orders-mysql fixed (TLS CA)

- **First apply:** 8 resources created. `orders-pg` came up. `orders-mysql` crash-looped: Flyway's first connection failed the TLS handshake with "signature check failed", so the rollout wait timed out after 10 minutes and the Deployment was tainted.
- **Cause:** `mysqld` presents the operator's internal certificate to clients too (`@@ssl_cert` = `/etc/mysql/ssl-internal/tls.crt`), and `mysql-ssl` and `mysql-ssl-internal` hold different self-signed root CAs. Checked with `openssl verify`: the served certificate verifies against the internal CA only.
- **Fix:** the app now trusts `mysql-ssl-internal`.
- **Also fixed, two bugs in the new app checks:**
  - the zone check compared zone names against a count;
  - the health check expected `status` as the first JSON key.

## 2026-10-27: orders example app and k6 load written

- **App** (`relational/app/orders`):
  - Spring Boot 4.1.1 on Java 25: one image, with `ORDERS_ENGINE` choosing the PostgreSQL or MySQL repository.
  - The writer endpoint handles writes and reads by key; the reader endpoint handles searches.
  - Retries cover transient failures, and creates are idempotent on `requestId`.
  - Session timeouts are set; MySQL writer reads use `wsrep_sync_wait=1`.
  - TLS is verified against each cluster's CA; the app logs in as each database's `app` user.
  - The planted missing index on `orders (customer_id, status)` is in place, with no foreign key.
- **Tests:** `mvn test`, 8 passed (4 per engine) against `postgres:16.13-trixie` and `percona/percona-xtradb-cluster:8.0.44-35.1`.
  - The CloudNativePG image can't be used here: it has no entrypoint.
  - PXC's strict mode refuses `GET_LOCK`; Flyway migrated it anyway.
- **Image:** `orders:0.1.0`, built and loaded into the kind nodes (`scripts/build_app.sh`).
- **Load:** `app/k6/orders.js`, run by `scripts/load_test.sh` as a Job using k6 1.8.1.
  - Open model; the mix is create 20 / read 45 / search 20 / update 10 / delete 5.
  - The SLO is a p95 and an error rate per operation, plus `orders_lost == 0`: each virtual user re-reads its own acknowledged orders.
  - Results go to Prometheus by remote write. A local probe confirmed the metric names (`k6_http_req_duration_p95` and so on, in seconds) and the labels `op`, `engine` and `testid`.
- **Dashboard:** "Relational / Orders load (k6 and app)", 15 panels.
- **Terraform:** `relational/modules/orders-app` and the new root `relational/environments/dev/app` (passes `terraform validate`).
- **Checks:** `check_resources.sh` gains an orders-app section, skipped until that root is applied (still 35/35).

## 2026-10-27: restart and shutdown scripts verified

- **`platform/scripts/docker_shutdown.sh [--keep-docker]` (new):**
  - stops the workers together, then the control plane (`docker stop -t 120`, about 2 minutes);
  - then quits Docker Desktop and waits for its VM to exit, unless `--keep-docker` is given.
- **`platform/scripts/docker_restart.sh` (rewritten):**
  - starts Docker Desktop if it isn't running;
  - every wait needs evidence newer than the restart: node Leases renewed, every container started after it, Galera "3 Synced" on each node, the PXC operator reporting `ready 3`, 2 PostgreSQL replicas streaming, and fresh `up` and `mysql_up` scrapes;
  - the first version waited on status saved before the shutdown, so every wait passed at 0 s;
  - one run passed Galera seconds before pxc-1's readiness probe and its exporter caught up (31/35), which is why the operator and `mysql_up` waits were added.
- **`private/scripts/checks.sh` `refused()`:**
  - now requires the server's own refusal message (a regex);
  - before, a refused-connection check passed when the server was simply down.
- **Verified:** shutdown, then restart, twice. The final run gave platform 13/13 and relational 35/35, about 4 minutes from start.
- **Runbook 27 evidence (PXC full-cluster crash recovery, `autoRecovery`):**
  - the operator bootstraps the node with the highest seqno (pxc-0, seqno 48);
  - the other two exit once and rejoin by IST;
  - 3 Synced members about 3.5 minutes after Docker starts.

## 2026-10-27: cluster stopped for a laptop reboot

The laptop ran flat overnight and was deep in swap (4.8 of 6 GB); the
Docker Desktop VM held 6.9 GB. The four kind node containers were stopped
gracefully (`docker stop -t 120`, done in 90 s) and Docker Desktop quit.
Nothing destroyed: cluster, volumes and Terraform state remain. Restart:
start Docker Desktop, `docker start` the control plane then the workers,
then run both `check_resources.sh`. All three Galera nodes stopped
together, so MySQL comes back through the operator's full-cluster crash
recovery (`autoRecovery`): a test of runbook 27 for free.

## 2026-10-26: database metrics and dashboards

Committed the verified platform + relational state first (`ea4cf2c`).

- PostgreSQL: a PodMonitor per cluster (CloudNativePG's
  `enablePodMonitor` is deprecated in 1.30); the operator chart now creates
  its own PodMonitor and the official CloudNativePG dashboard (66 panels).
- MySQL: decided exporter over PMM. A `mysqld_exporter` v0.20.0 sidecar on
  each PXC node (v0.21.0 is four days old), logged in as the operator's
  `monitor` user through mysqld's socket on the shared `tmp` volume
  (read-only; a socket counts as secure transport, so
  `require_secure_transport` stays on); statement digests enabled for the
  missing-index runbook. PodMonitor and a 25-panel MySQL / Galera dashboard
  written for this repo (the exporter's own mixin dashboard is dated and
  has no Galera panels).
- Checks: the relational check gains six metrics checks (all scraped,
  `mysql_up`, Primary Component seen by Prometheus, dashboards loaded); the
  Prometheus query helper moved to `scripts/checks.sh`. Before the apply:
  29 passed, 6 failed, as expected.
- Applied: relational `operators`, then `clusters`. Adding the sidecar
  rolled the PXC nodes one a minute, writer last (pxc-2 22:27:40, pxc-1
  22:28:40, pxc-0 22:29:40); writes kept flowing. The apply itself returned
  in 0 s: its wait (`status.state = ready`) was still true from before, so
  the user's check right after it caught the rollout mid-way (28/35: state
  `initializing`, Galera `2 Primary`, sidecars not ready yet, PodMonitors
  not yet loaded by Prometheus). Re-run after the rollout: 35/35. README
  now says to wait for `ready` after a cluster change. The plan's warning
  about an `x-kubernetes-preserve-unknown-field` comes from the PXC CRD's
  untyped sidecar schema and is harmless. Every dashboard query returns data except the two statement-digest
  tables: the collector succeeds, but nothing has queried `appdb` yet (the
  exporter skips statements with no schema and the system schemas). They
  fill when the CRUDS app runs.

## 2026-10-26: first apply

All four roots applied (cluster 1m45s, monitoring 2m54s, operators 18s,
clusters 9m51s, mostly image pulls). Two fixes:

- `pg` was created and healthy, but the apply failed with "Provider produced
  inconsistent result": CloudNativePG writes its own settings (`wal_level`,
  `archive_mode`, `shared_preload_libraries`, ...) into
  `spec.postgresql.parameters`, and Terraform marked the resource tainted.
  The module now lists that path in `computed_fields`. Fixed with
  `terraform untaint` and an in-place apply (it only recorded
  `computed_fields` in state; nothing changed on the cluster), not by
  recreating it.
- The Galera check sorted the status variables the wrong way (`Primary 3`);
  now ascending (`3 Primary`). The cluster itself was fine.
- Grafana had no requests or limits (BestEffort) and reached 708 MiB working
  set after browsing dashboards. A cluster-wide check found the same for
  every add-on we install: the CNPG operator, the Prometheus operator and
  config-reloaders, kube-state-metrics, node-exporter (Grafana's namespace
  panels show "No data" for them, since they divide by requests). All now
  have memory requests and limits; Grafana 256 Mi / 1 Gi with
  `GOMEMLIMIT=900MiB`. kind's own kube-system pods are left as kind ships
  them. Platform `services` applied (37 s, no restarts; every monitoring pod
  now Burstable); Alertmanager still lacked a limit: 128 Mi added and
  applied (11 s). Relational `operators` applied (8 s; the `pg` pods kept
  running while the operator pod was replaced).
- Grafana then showed the CNPG operator at 134% of its 64 Mi memory request
  (working set 86 MiB, of which RSS 27 MiB; the rest is file cache, which
  the kubelet counts for eviction). Request raised to 128 Mi (limit stays
  256 Mi). CPU limits are deliberately not set: they throttle even when the
  node has spare CPU; requests guarantee the share.
- Measured every add-on's working set against its request; four more ran
  above it: Grafana 532 MiB (request 256 -> 640 Mi), its two sidecars
  about 80 MiB each (64 -> 128 Mi, limit 192 -> 256 Mi), and the PXC
  operator 63 MiB against the chart's default 20 Mi (now 128 Mi, limit
  512 Mi, and the chart's 200m CPU limit removed). The relational check
  confirms both operators' requests and limits. Applied: `services` 22 s,
  `operators` 9 s; platform 13/13, relational 29/29.
- For runbooks 16 (tune) and 34 (OOM): each PXC node's working set is
  470-545 MiB of its 768 Mi hard limit while idle. The operator sized the
  InnoDB buffer pool from the memory given: 384 MiB (half of 768 Mi), and
  `max_connections` = 64 (runbook 32, connection exhaustion). As the buffer
  pool fills under load the working set will approach the limit.
  PostgreSQL uses 64-70 MiB of 512 Mi.
- The platform check now covers monitoring (Prometheus, Alertmanager,
  Grafana ready; remote-write receiver on; scrape targets 26 up, 0 down;
  25 dashboards loaded; every monitoring container has a memory limit). The
  relational check also confirms the CNPG operator's request and limit.
- Found, not fixed: each kind node reports the whole VM (4 x 8 CPUs,
  13.6 GiB = 32 CPUs, 54.5 GiB allocatable on an 8-CPU, 13.6 GiB VM).
  Recorded in DESIGN.md (lab limits); the fix (kubelet `system-reserved`)
  needs the cluster recreated, so it goes with the dedicated-nodes change.

## 2026-10-26: storage and lab-limit notes

From discussion: storage media and interfaces (NVMe vs SAS/SATA, SSD
random-write history), capacity tiers and the rebuild-time cap on data per
node, noisy neighbours on shared disks (drive, OS, storage and architecture
fixes) recorded in `datastore-clusters/docs/DESIGN.md`. RUNBOOKS.md gains
SSD class and TRIM, I/O isolation, the rebuild-time capacity rule, a
noisy-neighbour drill in runbook 2, two common-problem rows, and "What the
laptop lab can and can't test" (29 real, 3 relative, 6 workaround, 2
simulated; hardware-only practices documented).

## 2026-10-26: runbooks defined

`datastore-clusters/docs/RUNBOOKS.md`: 39 runbooks in five groups with a
common template, RPO/RTO/SLO terms, capacity rules for a private cloud
(headroom bought in advance; no thin-provisioned storage beyond what is
backed), storage practices, and a symptom-to-runbook table. Applying it:
the PostgreSQL module now enables data checksums at initdb (off by default
before PostgreSQL 18; pg_upgrade needs them to match).

Revised the same day from the user's operating experience: 39 runbooks
(added disk and hardware health, writer failure, reader failure; storage
migration now includes reformatting); storage practices for index/temp
volumes, mkfs-time filesystem choices, journaling, write-cache cards and
power-loss protection, SMART health, consistent snapshots; a table of how
each engine elects a writer; the example apps get a planted missing index.
To do: `failover_test.sh` gains a reader target.

## 2026-10-26: whole datastore range, monitoring, design notes

Restructured (still unapplied) so every datastore category can live in one
tree: `datastore-clusters/platform/` (shared kind cluster + services) and
`datastore-clusters/<category>/modules/<engine>/{operator,cluster}` with
`environments/dev/{operators,clusters}`. Relational moved in (namespace
`relational`). Shared script helpers: `scripts/checks.sh`.

Added: platform `services` root with kube-prometheus-stack 92.3.0
(Prometheus, Grafana, Alertmanager). Planned per category: an example CRUD
app and a k6 load test. Catalogue: 10 categories with 2-3 engines each, 20
runbooks (`datastore-clusters/README.md`). Brainstorming and conclusions
recorded in `datastore-clusters/docs/DESIGN.md`.

All roots validate; tflint and trivy 0 findings.

## 2026-10-26: older starting versions, runbook plan

stage3 defaults now start old on purpose: PostgreSQL 16.13 and PXC 8.0.44
(MySQL 8.0, past upstream end of life in April 2026). Seven day-2 runbooks
are planned (monitor, back up, patch, tune, replace a node, force an
election, major upgrade); see `datastore-clusters/README.md`. Backup store:
not MinIO (community edition unmaintained since late 2025); Garage or
SeaweedFS.

## 2026-10-26: datastore-clusters written

Why: the AWS Free plan rejects the Aurora design that was in
`aws/datastore-clusters` (removed 2026-10-26): no Aurora MySQL, and Aurora
PostgreSQL only in serverless "express" mode. A paid plan is not
affordable, so the same HA design is built here first, at no cost.

What (details in `datastore-clusters/README.md`):
- stage1-platform: kind cluster `datastore-dev` (kind provider 0.11.0,
  Kubernetes v1.35.0), three workers labelled zones `dc1-a/b/c`, own
  kubeconfig `~/.kube/kind-datastore-dev`.
- stage2-operators: CloudNativePG 1.30.1 (chart 0.29.1), Percona Operator for
  MySQL/PXC 1.20.0 (chart 1.20.1), both cluster-wide.
- stage3-datastores: `pg` (PostgreSQL 18.6, 3 instances, required zone
  anti-affinity, ANY 1 quorum sync replication, failoverQuorum, TLS-only
  pg_hba) and `mysql` (PXC 8.4.8, 3 Galera nodes + 3 HAProxies, zone
  anti-affinity, require_secure_transport, app user/database).
- Scripts: `check_resources.sh`, `kube_use.sh`, `failover_test.sh pg|mysql
  [pod|zone]` (zone = `docker stop` the writer's node).

Choices:
- MySQL operator: Percona PXC, because its images are multi-arch. Oracle's
  MySQL Operator publishes arm64 only under separate `-aarch64` tags, which it
  doesn't select by itself on this M4.
- kind provider pinned to 0.11.0: 0.13.0 was 4 days old.

Checks: `terraform validate` passes for all three stages; tflint 0
findings, trivy 0.
