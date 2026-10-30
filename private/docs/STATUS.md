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
after a full Docker Desktop shutdown and restart. Runbook 17 (the missing
index, online) passes on both engines and puts the planted problem back
afterwards, so search still fails its SLO by design between runs. PXC
nodes at 2Gi with a pinned 768M buffer pool.

## 2026-10-30: runbook 26 mysql failed on the app tier; node-monitor grace period 20 s (to apply: rebuilds the cluster)

- **First run, mysql 03:26: FAILED** (`logs/runbook-26-mysql-20261030-032618-FAILED.txt`). Database fine: probe outage ~42 s, healed 56 s after the zone came back, 0 lost. But k6 requests failed until ~03:28:50, ~77 s: "no route to host" / "i/o timeout" to the orders-mysql Service. The app pod in the dead zone stayed in the Service until Kubernetes marked the node NotReady, after the 50 s default grace period (Kubernetes 1.35). The same 50 s is most of PostgreSQL's 61-64 s zone failover.
- **pg 03:36 (same night, 50 s grace): FAILED, not judged** (`logs/runbook-26-pg-20261030-033620-FAILED.txt`). Probe outage ~60 s (pg-2 -> pg-1; new writer after 57 s), healed 31 s after the zone came back; k6 saw 513 of 6693 requests fail (431 creates). The script then died at line 82 ("e: command not found", syntax error): it was edited while running (bash reads a script as it goes), so there is no verdict. The current file passes `bash -n`.
- **Fix (platform, chosen over judging only the database):** kind module `node_monitor_grace_period` (kubeadm patch on the control plane: kube-controller-manager `--node-monitor-grace-period`), dev set to 20 s. Changing it replaces the kind cluster: destroy and re-apply platform, relational clusters and app. fmt and validate pass; not applied.
- **Rebuilt 2026-10-30 evening:** platform cluster (plan shows the kubeadm patch; `--node-monitor-grace-period=20s` confirmed in the controller manager's manifest), platform check 6/6 before services; services, operators, clusters, app applied; both seeds 301/301 batches (3,000,000 orders each); relational check 45/45. Next: runbook 26 mysql, then pg.
- **Runbook 26 mysql passed (19:23 UTC, `logs/runbook-26-mysql-20261030-192335.txt`), but only just:** writer mysql-pxc-0 -> mysql-pxc-2 in 28 s (was ~42 s); probe write outage ~22 s; healed 46 s after the zone returned; 0 acknowledged writes lost, 0 failures after recovery; check 45/45. App outage by k6 ~60 s against RTO 60 s. Most of that is k6's 30 s dial timeout: the last failures (19:25:43) were requests that started ~19:25:13, when the dead zone's app pod left the endpoints. Counted by request start, users saw ~25 s. orders-mysql restarts 0 -> 2 (the dc1-a pod, when its node came back). To decide after the pg run: a shorter k6 request timeout, or judge by request start.
- **Runbook 26 pg FAILED (19:30 UTC, `logs/runbook-26-pg-20261030-193045-FAILED.txt`): no failover for ~314 s.** Cause: the CloudNativePG operator (1 replica) ran on datastore-dev-worker, the node of zone dc1-a, so it went down with the zone. Its pod was only evicted after the default 300 s `node.kubernetes.io/unreachable` toleration (TaintManagerEviction 19:37:12); the new operator promoted pg-2 at 19:37:19. Earlier pg runs failed over because the operator happened to be in another zone. Cluster healed 26 s after the zone returned; now healthy, primary pg-2. Proposed fix: 2 operator replicas spread across zones (leader election is already on), so a standby takes over within its lease.
- **Fix written (to apply: operators layer, Helm upgrade in place):** both operators 2 copies, required pod anti-affinity on `topology.kubernetes.io/zone` (`modules/postgresql/operator`, `modules/mysql/operator`). PXC's lease shortened from the chart's 60/40/10 s to CloudNativePG's 15/10/2 s. `check_resources.sh`: both operators 2 available, in 2 zones (4 checks fail until applied: 43/47). `runbook_26_zone.sh` prints each operator's zones in its preconditions. fmt + validate clean.
- **Operators applied (2 changed in place):** both operators 2/2, CloudNativePG in dc1-a + dc1-c (leader dc1-a), PXC in dc1-a + dc1-c (leader dc1-c). Check 46/47: "CloudNativePG operator scraped" expected 1 and saw 3 during the rollout (old pod still listed); now 2 targets, and the check expects 2 (both copies). Next: switch the pg primary to pg-1 (dc1-a, with the CloudNativePG leader) so runbook 26 kills the leader's zone, then run it.
- **Runbook 26 pg passed (19:57 UTC, `logs/runbook-26-pg-20261030-195733.txt`), operator not in the lost zone:** pg-2 (dc1-b) -> pg-1 (dc1-a) in 23 s; probe write outage ~28 s, app ~25 s (RTO 60 s); 0 acknowledged writes lost, nothing failed after 19:59:40; healed 31 s after the zone returned; check 47/47. The failover moved the primary to pg-1, in dc1-a with the CloudNativePG leader (264hf on datastore-dev-worker), so no switchover is needed: the next run kills the leader's zone.
- **Runbook 26 pg passed with the operator leader in the lost zone (20:15 UTC, `logs/runbook-26-pg-20261030-201516.txt`): the fix works.** pg-1 + CloudNativePG leader (264hf) in dc1-a; the standby copy (rwsnh, dc1-c) acquired the lease at 20:16:27, as the zone went down; the node went NotReady ~20:16:50, failover delay 5 s, failover 20:16:55. New writer pg-2 (dc1-b) after 30 s; probe write outage ~35 s; 0 acknowledged writes lost, none failed after 20:17:31; healed 31 s after the zone returned; check 47/47. The operator takeover cost nothing: the 20 s node grace period is what gates the failover. App outage by k6 ~60 s against RTO 60 s, again inflated by k6's 30 s dial timeout (last failures 20:17:18-22 started ~20:16:50, when the dead zone's app pod left the endpoints); by request start ~25-30 s. orders-pg restarts 1 -> 3 (the dc1-a app pod when its node came back). Open: shorten k6's request timeout so the app outage measures what users saw.
- **k6 request timeout 15 s (to apply: app layer, ConfigMap `orders-k6` only):** `app/k6/orders.js` sets `timeout: '15s'` on every CRUDS request. Above the app's own budget (~13 s of retries, then 503), below k6's 30 s connect wait. Validate clean. Next: apply, then runbook 26 mysql and pg again.
- **Applied; reruns passed:** mysql (20:29 UTC, `logs/runbook-26-mysql-20261030-202955.txt`): mysql-pxc-0 -> mysql-pxc-2 in 18 s, database ~14 s, app ~10 s, healed 46 s after, 0 lost, 47/47. pg (21:10 UTC, `logs/runbook-26-pg-20261030-211057.txt`): pg-2 -> pg-1 in 24 s, database ~28 s, app ~25 s, healed 31 s after, 0 lost, 47/47. Caveat: in neither run was an app pod in the lost zone, so the 15 s timeout's worst case is not yet measured. Each pass replaces that engine's older runbook-26 log, so the leader-takeover pass (201516) survives only here and in RUNBOOKS.md. Seen: the orders-pg pod in dc1-a exits 1 on startup each time its node returns (can't reach PostgreSQL yet), then starts on the retry: 2 restarts per return; harmless, later.
- **Runbook 26 reports its case; runbook 13 written (uncommitted):** runbook 26's preconditions list the app pods' zones and the result says whether an app pod was in the lost zone (the worst case). The app-pod selector in the runbook scripts also matched k6's job pods (same instance label); now `APP_PODS` in `runbook_lib.sh` adds `app.kubernetes.io/name=orders`. New `runbook_13_patch.sh pg|mysql`: reads the target image from `environments/dev/clusters/variables.tf`, starts k6 (15m), asks for the clusters apply in a second terminal, times each member's return on the new image and the writer's move, checks each server's own version, budget 30 s of app errors, 0 lost. Targets: PostgreSQL 16.13 -> 16.15-standard-trixie (newest 16.x), PXC 8.0.44 -> 8.0.46-38.1 (newest 8.0, 2026-07-23). CloudNativePG's `primaryUpdateMethod` was the default `restart` (the primary restarts in place, no writer meanwhile); set to `switchover` in `modules/postgresql/cluster` (to apply: clusters root, no restart expected) and checked by `check_resources.sh` (48 checks).
- **Applied primaryUpdateMethod (check 48/48).** Runbook 26 mysql at 21:25 UTC (`logs/runbook-26-mysql-20261030-212527-FAILED.txt`) passed every test (database ~24 s, app ~20 s, 0 lost) but failed the new primaryUpdateMethod check, run before that apply. Stopping dc1-a also took pg-1, then the pg primary: failover to pg-2 at 21:27:08 (expected; a zone holds both engines). Runbook 26 pg at 21:33 (`logs/runbook-26-pg-20261030-213358.txt`) passed: pg-2 -> pg-1 in 26 s, database ~30 s, app ~30 s, 0 lost, 48/48; no app pod in the lost zone. **Found:** orders-pg-hsm5p (dc1-c) OOMKilled at 21:35:38 during that failover (working set 511.8 of 512 MiB; the EOF burst in k6); orders-mysql-c2lsl peaked at 507.8 MiB in a mysql run. At rest ~250 MiB. The heap is 60% of the limit (298 MiB) and the rest (~215 MiB non-heap and native) leaves no headroom when requests pile up during an outage. To decide: raise the app's memory and/or lower its heap share.
- **Runbook 13 pg target set:** `postgres_image` default 16.13 -> 16.15-standard-trixie (not applied; `runbook_13_patch.sh pg` asks for the apply).
- **App memory fix written (to apply after runbook 13: build_app.sh, then the app root):** orders 0.1.3, `-XX:MaxRAMPercentage=50` (was 60) and 768Mi request and limit (was 512Mi): 384 MiB heap, ~170 MiB to spare at the failover peak. +1 GiB of requests over the 4 app pods; the 3 kind workers share one Docker VM (~8.8 GiB in use of 13.6). The check_resources.sh check for it waits until runbook 13 is done (that run calls the script at its end).
- **Runbook 13 pg passed (21:48 UTC, `logs/runbook-13-pg-20261030-214814.txt`):** 16.13 -> 16.15. Replicas first (pg-3 +51 s, pg-2 +119 s), switchover pg-1 -> pg-2 at +122 s, then pg-1 (+187 s); 188 s from the first change to whole; every server reports 16.15. App errors ~5 s (3 of 17,922 requests failed; k6's own SLO passed); 0 lost; 48/48. The run waited 5.5 min for the apply.
- **App memory applied:** orders 0.1.3 on all 4 pods, 768Mi; JVM heap max 371 MiB (was 298 by the same metric). `check_resources.sh` checks each app's 768Mi (50 checks, 50/50).
- **Runbook 13 mysql target set:** `pxc_image` default 8.0.44-35.1 -> 8.0.46-38.1 (not applied; the runbook asks).
- **Runbook 13 mysql passed (22:12 UTC, `logs/runbook-13-mysql-20261030-221209.txt`):** 8.0.44 -> 8.0.46. SmartUpdate: mysql-pxc-2 (+100 s), mysql-pxc-1 (+222 s), then the writer mysql-pxc-0 (+336 s); HAProxy moved writes to mysql-pxc-2 at 22:18:57 and back to mysql-pxc-0 at 22:20:20; 347 s to whole; every server reports 8.0.46-38.1. App errors ~20 s (22:18:45-22:19:00, as the writer stopped; 65 of 17,880 requests); 0 lost; 50/50. Runbook 13 done on both engines; RUNBOOKS.md and relational/README.md updated. Uncommitted.
- **Stopped for the night after the teardown.** Nothing is running. Resume at step 2 (apply platform `cluster`, check the grace period with `docker exec datastore-dev-control-plane grep grace /etc/kubernetes/manifests/kube-controller-manager.yaml`), then services, operators, clusters, `build_app.sh`, app, seed both engines to 3,000,000, then runbook 26 mysql and pg. All changes uncommitted.
- **Teardown done (2026-10-30):** app (10), clusters (8), operators (2), services (1), kind cluster (1) destroyed in that order. CNPG's CRDs went with the cluster (Helm keeps them).
- **Runbook 26 now judges the app's outage too:** `k6_fail_window` (runbook_lib) gives the first and last failed k6 request (creates, updates, deletes, reads; 5 s resolution); both it and the probe's outage must be within the 60 s RTO. On the failed run's data it reports 03:27:38-03:28:53, ~80 s (log: 03:27:33-03:28:50).

## 2026-10-30: runbook 26 (zone outage) scripted; to run

- **`runbook_26_zone.sh pg|mysql`:** finds the writer's zone, starts k6 outside it, runs `failover_test.sh <engine> zone` (stop the node, probe the outage, start it, wait for every member Ready), then judges: 0 lost, no request failing from 30 s after the probe recovered, write outage within the 60 s RTO, relational check passes. The zone also holds an app pod, so the app tier loses a pod too (e.g. pg-2's node: orders-pg, mysql-pxc-2, an HAProxy).
- **`load_test.sh`:** `K6_AVOID_ZONE=<zone>` keeps the k6 pod out of a zone (server dry run: the affinity appears only when set).
- **`failover_test.sh zone`** no longer logs as runbook 26; the runbook does. Its committed runbook-26 logs (probe only) are replaced by the runbook's first passes.
- **Expect PostgreSQL to fail the RTO** (61-64 s in the probe-only runs; detection by Kubernetes is 48 s of it).

## 2026-10-30: runbook 1 (alerts) passes on both engines

- **Before:** no database or app alerts at all, only kube-prometheus-stack's Kubernetes rules; Alertmanager's only receiver is "null".
- **New PrometheusRules** (the shared Prometheus loads every rule: `ruleSelector {}`):
  - `modules/postgresql/cluster/alerts.tf`: instance down, primary count not 1, replicas not streaming, replication lag > 30 s, connections > 80%, memory > 80%.
  - `modules/mysql/cluster/alerts.tf`: member down (mysql_up or wsrep_cluster_size), not Primary, not Synced 5 m, apply queue > 50, connections > 80%, memory > 80%.
  - `modules/orders-app/alerts.tf`: p95 per operation over its k6 SLO for 5 m (with traffic), errors > 1%.
  - Every expression run as a query against live Prometheus first: all parse; all healthy now. MySQL search p95 over the last hour of load is 857 ms, so its SLO alert will fire under load (the planted missing index); pxc-2 at 64% of its memory limit (83% under pt-osc on 10-27 would have fired).
  - No disk alert per volume: local-path volumes report no usage (no `kubelet_volume_stats_*`). No certificate or backup metric.
- **`runbook_1_alerts.sh pg|mysql`:** see RUNBOOKS 1. Tested read-only so far: usage; `alert_state` (Watchdog firing, KubeJobFailed pending, unknown none; a jq `index()` bug found and fixed); the Alertmanager lookup (Watchdog there); `firing_now` (nothing of ours). Fixed before running: "firing now" filtered on a namespace label that `count()` alerts don't have.
- **Applied 2026-10-30 02:0x:** clusters root (pg-alerts, mysql-alerts) and app root (orders-pg-alerts, orders-mysql-alerts), 2 adds each, nothing else changed. All 4 groups visible in Prometheus a minute or two later.
- **First run, pg 02:02: FAILED at step 0, "0 of the 4 rule groups":** started seconds after the apply, before the operator had pushed the rules to Prometheus. Step 0 now waits up to 3 minutes.
  - That failure exposed a worse bug: the exit trap's undo used `$VICTIM` before step 0 set it; under `set -u` the trap stopped there, so the log was not renamed `-FAILED` (renamed by hand), and a failure mid-test could have left a trigger in place. Fixed: `VICTIM` starts empty and the undo runs in a subshell (runbook 23's trap too). Tested with a scratch script whose undo hits an unset variable: the log still ends `-FAILED.txt`, exit 1.
- **Second run, pg 02:06: FAILED, PostgreSQLInstanceDown did not fire in 300 s** (log kept locally; the undo ran and unfenced pg-1). Fencing worked, but `cnpg_collector_up` stayed 1 for pg-1 the whole time (it reports the exporter, not PostgreSQL), and `cnpg_collector_last_collection_error` stayed 0. What did change: pg-1's `cnpg_pg_replication_in_recovery` series stopped a minute after fencing (count 3 -> 2 from 02:08:30), and streaming replicas went 2 -> 1.
  - Fix (to apply): the alert counts `cnpg_pg_replication_in_recovery` series, reported only while PostgreSQL answers. On the 02:06 data it would have fired about 02:09:30.
- **Third run, pg 02:23 (new InstanceDown rule applied): 2 of 3 alerts passed, then FAILED on the connections test's pod.**
  - PostgreSQLInstanceDown: fired 91 s after fencing pg-1, in Alertmanager, cleared 31 s after unfencing.
  - PostgreSQLReplicationLag: fired 151 s after pausing replay on pg-1, cleared 61 s after resuming.
  - PostgreSQLConnectionsHigh: the pod's YAML was invalid. The psql connection string's double quotes sat inside a double-quoted `command` string. Now a block literal; both engines' pods pass `kubectl apply --dry-run=server`.
- **Fourth run, pg 02:37: passed** (`runbook-1-pg-20261030-023700.txt`). InstanceDown fired 91 s after fencing pg-1, cleared 31 s after unfencing; ReplicationLag fired 152 s after the replay pause, cleared 61 s after resuming; ConnectionsHigh fired 111 s after the pod opened 83 sessions on pg-1, cleared 61 s after it went. Each reached Alertmanager. The search SLO alert stayed quiet. k6: 0 of 18,000 requests failed, 0 lost; search p95 205 ms (usually ~70 ms: reads squeezed onto one replica while pg-1 was fenced, paused or full). Relational check 45/45.
- **mysql 02:55: passed** (`runbook-1-mysql-20261030-025556.txt`). MemberDown fired 111 s after freezing pxc-1's mysqld (the liveness probe restarted it twice, 02:59), cleared 91 s after thawing; ApplyQueue fired 112 s after desync + FLUSH TABLES WITH READ LOCK on pxc-1, cleared 61 s after; ConnectionsHigh fired 112 s after 143 idle sessions on pxc-1, cleared 31 s after. Each reached Alertmanager. The search SLO alert fired under load and cleared 302 s after it ended. 0 lost; relational check 45/45.
  - **Finding: a hung Galera node stalls the whole cluster's writes.** All 12 failed writes (creates) came at 02:57, as pxc-1, a non-writer, froze: Galera waits on every member until it evicts one that stops answering (suspect/inactive timeouts, ~5-15 s). A clean pod deletion (runbooks 24, 25) failed none, because a stopping node leaves the group.
  - 36 searches failed 03:05-03:12, after the tests (search p95 3.8 s, max 10.8 s). Cause not proven; likely pxc-1 back with an empty buffer pool after its restarts, scanning from disk on top of the planted missing index. The user's VPN, turned on during the session, does not touch in-cluster traffic (Docker's internal network; kubectl on 127.0.0.1).
- **Runbook 1 passes on both engines.** Not fired: primary/quorum loss, memory, disk, certificates, backups; error-rate alert defined but not fired on purpose. Alertmanager's receiver is still "null".

## 2026-10-29: runbooks 23 and 25 pass on both engines; runbooks 5 and 26 logged; zone heal time fixed

- **Logs:** `load_test.sh … run` logs as runbook 5, `failover_test.sh … zone` as runbook 26 (into the caller's log when a runbook runs them). Zone mode now exits 1 if the cluster has not healed in 10 minutes (it only printed a warning). `failover_test.sh` chains its cleanup with the log's exit trap.
- **`runbook_lib.sh`:** the shared parts: log, cluster health (`whole`, `wait_whole`), writer lookup, the background k6 load, k6 counters in Prometheus at a point in time, the write/read verdict, the final check. Runbook 24 now uses it, so it needs a rerun; runbook 17 does not use it yet.
  - `judge_writes` also fails on reads still failing after the cutoff (new for runbook 24).
  - Checked read-only on the live cluster: both clusters whole, writers pg-2 and mysql-pxc-0, the counter at a time matches the 21:21 log (2,113 writes).
- **`runbook_25_reader.sh`:** deletes a replica's pod (pg: a CloudNativePG replica; mysql: a node HAProxy is not writing to) under k6 load. No write may fail or be lost; the writer must not move; reads must all succeed from 30 s after the cluster is whole again.
- **`runbook_23_switchover.sh`:** switches the writer and back under 6 m of k6 load. Fails if a write fails 30 s after either switch, if a write is lost, or if the writer does not end where it started.
  - pg: the status request `kubectl cnpg promote` makes (patched with `--subresource=status`; the plugin isn't installed).
  - mysql: `pxc_maint_mode=MAINTENANCE` on the writer. HAProxy's `haproxy_check_pxc.sh` marks any node not `DISABLED` down (read in the pod). An exit trap puts the node back in service if the script stops early.
- **Results (20 requests/s, all logged):**
  - **25 pg 21:43: passed.** Replica pg-1 deleted; whole again after 31 s, replay lag under 1 ms. 0 of 2,111 writes failed, 0 reads failed, 0 lost, primary unchanged.
  - **25 mysql 21:54: passed.** mysql-pxc-1 deleted; whole after 56 s. 0 of 2,101 writes failed, 0 reads failed, 0 lost, writer unchanged.
  - **23 pg 22:01: passed.** pg-2 -> pg-1 in 4 s, back in 3 s, whole after ~15 s each. 18 of 2,538 writes and 1 read failed, 17 of them in the first switch (create p95 4.1 s, max 10.8 s); none 30 s after either switch; 0 lost; one primary, the original.
  - **23 mysql 22:09: passed.** Maintenance moved writes pxc-0 -> pxc-2 in 2 s; back in service, HAProxy returned to pxc-0 in 8 s. 0 of 2,466 writes failed, 0 lost. The exit trap's restore ran as the normal switch back.
  - **24 pg 22:16 and mysql 22:23 (on runbook_lib.sh): passed.** pg ~17 s probe outage, 0 app writes failed; mysql 0 s; 0 lost on both. These logs replace the earlier ones.
  - **5 pg 22:30: FAILED, by mistake:** duration `2` with no unit reached k6 as 2 ms. Exercised the runbook 5 log's failure path. `load_test.sh` now rejects a rate, duration or order count it can't use before starting a Job (tested: `2`, `20x`, `0`, `abc` rejected; `90s`, `2m`, `1h30m` accepted).
  - **26 mysql 22:35: writes recovered in ~50 s (RTO 60 s), but "healed 5 s after the zone came back" was false.** The node returned at 22:37:03; pxc-0's database started 22:37:11 and was ready about 22:37:52. The operator's status still read "ready 3" from before the outage (the same false 5 s as the 20:59 test). The log ends "Log: …", so the chained exit trap works.
    - Fix: the heal wait also needs all three member pods Ready (Kubernetes set them not ready when the node was lost, so Ready now means since it came back). Tested read-only: 3 of 3 Ready on both clusters now.
  - **5 pg 22:39: passed** (`load_test.sh pg run 20 2m`): every SLO met, 0 failed, 0 lost; the pass removed the 22:30 failed log.
  - **26 mysql 22:50 (heal fix): ~46 s outage; healed 46 s after the zone came back**, a real number this time.
  - **26 pg 22:52 (heal fix): ~64 s outage, over the 60 s RTO** (61 s at 21:02; detection by Kubernetes dominates, see above); healed 36 s after the zone came back.
  - `failover_test.sh` measures but does not judge the RTO, so a zone log can be kept while over it. A runbook 26 script with k6 and an RTO verdict is still to write.

## 2026-10-29: runbook 24 (writer failure) passes on both engines; PostgreSQL failoverDelay 30 s, smartShutdownTimeout 15 s; one log per runbook

- **failoverDelay (to apply):** the PostgreSQL module has a new `failover_delay` variable (`spec.failoverDelay`, default 0); the clusters root sets 30.
  - Why: on the 2026-10-28 cold start, CloudNativePG found the primary still starting and failed over at once (pg-2 to pg-1). 30 s lets a starting primary keep its role.
  - Cost: up to 30 s more write outage when a primary really dies. `failover_test.sh pg` will measure it.
  - Applied 2026-10-29: the plan changed only `failoverDelay` 0 -> 30 on `pg`, in place; no pod restarted. Platform check 13/13 afterwards.
- **Logs:** `runbook_log` keeps only the latest log of each name. A pass deletes every older log of that name (passes and failures); a failure deletes older failures but keeps the last pass.
  - Tested with a scratch script: pass, fail, fail, pass, fail, plus a similarly named log (`runbook-17-pg-big-...`) that must not be touched. Every step left the expected files.
- **Runbook 24 (writer failure), new `runbook_24_writer.sh pg|mysql [rate] [duration]`, passes on both engines:** k6 at 20 requests/s for 5 m, kill the writer's pod via `failover_test.sh`, then judge:
  - the probe's write outage within the 60 s RTO;
  - 0 acknowledged writes lost (k6 `orders_lost`);
  - 0 app writes failing from 30 s after the probe recovered until the load ends (Prometheus `@` time query, checked against the 10-28 run: 1,647 writes, as logged);
  - the old writer back as a member (pg 2 replicas streaming; Galera 3 Synced); relational check passes.
- **First run, PostgreSQL 19:17 (FAILED, log kept locally):** primary pg-1 deleted at 19:18:08; pg-2 promoted at 19:21:11.
  - The probe's writes failed for 184 s, far over the 60 s RTO. The app's writes all succeeded: 0 of 2,167 failed, the slowest took 2.9 s, 0 lost.
  - Cause: a deleted primary does a smart shutdown first. It waits up to `smartShutdownTimeout` (default 180 s) for clients to leave, refusing new connections; open ones keep working. The app's pools never leave, so it waited the full 180 s. Failover started on time at 30 s (failoverDelay), then waited for the replicas' WAL receivers to stop, which happened only at the fast shutdown.
  - So new connections (the probe, a restarted app pod, a pool replacing a connection) failed for 3 minutes while old ones worked.
  - Fix (applied 2026-10-29): new module variable `smart_shutdown_timeout`; the clusters root sets 15. Expect the outage to be about 30 s (delay) plus a few seconds.
- **Second run, PostgreSQL 19:28: passed** (`runbook-24-pg-20261029-192840.txt`; the pass deleted the failed log, as designed).
  - pg-2 deleted at 19:29:49; pg-1 promoted 33 s later. Probe outage ~33 s (RTO 60 s); the old primary rejoined as a replica at once.
  - The app saw the outage this time: 53 of 2,216 writes failed (create p95 10 s, max 12.7 s, as requests waited for a connection); 9 reads failed too. 0 failed after 30 s past recovery; 0 lost; no app restarts.
  - Relational check 45/45 afterwards.
  - Trade-off: 30 s of the 33 s is failoverDelay. Setting it to 0 would cut the outage to a few seconds, at the price of the cold-start failovers seen 10-28.
- **MySQL 20:23: passed** (`runbook-24-mysql-20261029-202354.txt`).
  - Writer mysql-pxc-0 deleted at 20:25:07; HAProxy sent writes to mysql-pxc-2 within 2 s. Probe: 0 failed writes. App: 0 of 2,130 writes failed, 0 lost, no restarts.
  - The app's reader pools found dead connections to pxc-0 at 20:26:07 ("No operations allowed after connection closed"); Hikari validated and replaced them, so no request failed.
  - pxc-0 rejoined; the cluster was whole 46 s after the probe finished. Relational check 45/45.
  - One search "took" 4 min 14 s and the k6 run lasted 9 min: the laptop idle-slept 20:27:20-20:31:34 (254 s, pmset log; battery 16%), and Prometheus has no scrapes then. After the failover, so the verdict stands. Search missed its SLO because of the planted missing index, as expected.

  - Also: runbook 24 now checks RPO and RTO before "the load ended too soon" (that one hid the real failure).
- **`failover_test.sh pg zone` 20:55 (after the edits): writes recovered, but ~87 s, over the 60 s RTO.** The node was stopped at 20:55:24.
  - Detection took 50 s: the operator could not read the pod's status from 20:56:14, the same moment Kubernetes marked the node NotReady (its node-monitor grace period).
  - Then the 30 s failoverDelay; pg-2 promoted at 20:56:48; healed 31 s after the node came back.
  - So a zone loss costs detection (~50 s) plus failoverDelay; only failoverDelay is ours to tune.
- **`failover_test.sh mysql zone` 20:59: ~43 s outage, within the RTO.** Writer pxc-0's node stopped at 20:59:30; HAProxy moved writes to pxc-2 47 s later, once its health check gave up on pxc-0. Platform check 13/13 beforehand.
  - "Healed 5 s after the zone came back" is too quick to trust: the PXC status may still have read "ready" from before (the trap `docker_restart.sh` documents). Not re-checked.
  - Both zone tests wrote one row more than the probe saw succeed (pg 21 vs 20, mysql 26 vs 25): a commit whose reply was lost in the failure. That is an extra row, not a lost one, and why retried writes must be idempotent.
  - Decision: failoverDelay 30 -> 5 s, applied 21:01 (plan: only `failoverDelay` 30 -> 5, in place).
- **`failover_test.sh pg zone` 21:02, failoverDelay 5: ~61 s outage, 1 s over the 60 s RTO.** Node stopped 21:02:35. Operator: pod status unreadable at 21:03:23 (48 s, Kubernetes noticing the lost node), failover at 21:03:29 (the 5 s delay), new primary labelled at 21:03:32; the probe's next write a few seconds later. Healed 30 s after the node came back.
  - Detection is 48 of the 61 s, and failoverDelay 0 would save only 5 more.
- **Runbook 24 pg 21:21, failoverDelay 5: passed** (`runbook-24-pg-20261029-212129.txt`, replacing the 19:28 log). pg-1 deleted 21:22:38; pg-2 promoted 17 s later: the old primary's 15 s smart shutdown plus a few seconds (promotion waits for it to stop streaming). App: 0 of 2,113 writes failed (its pooled connections kept writing to the stopping primary; slowest 2.9 s), 0 lost, no restarts. Relational check 45/45. (App restarts 27 -> 31 between runs came from the zone tests, which stopped the nodes its pods ran on.) A zone loss on PostgreSQL here is about 60 s; meeting the RTO with margin needs faster node detection (the platform's node-monitor grace period), not operator settings.
  - `failover_test.sh mysql zone` straight after refused to start: PXC was still rejoining the restarted node (ready 3 a minute later); 3 scrape targets down for the same reason.
- **`failover_test.sh`:** passes when writes recover, even when no new writer appears (a PostgreSQL primary back within `failoverDelay` keeps its role; before, that read as a failure). Its last line, `RESULT start= first_fail= last_fail= writer=`, is what runbook 24 reads.

## 2026-10-27: PostgreSQL at 150 requests/s; orders 0.1.2 (no retries on a statement timeout)

- **Run:** `load_test.sh pg run 150 5m` at 3 million orders: FAILED, search only.
  - Search p95 6.08 s (max 12.33 s), 33% errors; read 11.9 ms, create 43.5 ms, update 38.8 ms, delete 33.3 ms p95; lost writes 0.
  - All 2,981 errors were reader-pool acquire timeouts (up to 78 waiting). The replicas did the scans (pg-3 3.6 cores, pg-1 2.9) while the primary pg-2 used 0.05: PostgreSQL's parallel scans on the replicas kept writes isolated.
  - **573 search retries remained** in 0.1.1. Spring translates PostgreSQL's `57014` (statement timeout) into `QueryTimeoutException`, a `TransientDataAccessException`, so each 5 s timeout ran again (the 12.3 s maximum).
- **The fix (0.1.2):** `Retrier` never retries a statement timeout: `QueryTimeoutException`, SQLState `57014`, or MySQL error 3024 (`max_execution_time`). MySQL's 3024 was not being retried under 0.1.1 (Spring leaves it uncategorized); its exclusion is defensive.
  - Test `doesNotRetryAStatementTimeout` uses Spring's real PostgreSQL translator; the suite passes 13/13. Image `orders:0.1.2` is loaded into the nodes; the `app_image` default is now `orders:0.1.2`.
- **To verify:** apply the app root, then rerun `load_test.sh pg run 150 5m`. Expect 0 search retries and a search maximum of about 8 s (3 s acquire plus 5 s statement).
- **Still to exercise before committing:** `docker_shutdown.sh` without `--keep-docker`.

## 2026-10-28: runbook 17 on PostgreSQL passed (repeatable version); restart waits for every target

- **Restart 22:3x:** relational 45/45; platform 12/13 for the third restart in a row, "36 up, 1 down" for a few seconds (all 37 up moments later).
  - Fix in `docker_restart.sh`: `scraped` also waits until no target is down (`count(up == 0)`). Passes on the live cluster; the down case is proven at the next restart.
- **Run `runbook-17-pg-20261028-224134.txt` (committed log), 3.0 million orders, primary pg-1:**

  | step | result |
  |---|---|
  | 0 | the index from 10-27 dropped (`DROP INDEX CONCURRENTLY`) |
  | 1 before | Parallel Seq Scans: 140 ms (status), 68 ms (30 days) |
  | 3 change | `CREATE INDEX CONCURRENTLY` in 2 s, first attempt |
  | 4 during (20 req/s) | 1,647 writes, 0 failed, 0 lost; write p95 3-5 ms (no visible slowdown, unlike pt-osc) |
  | 5 after | valid on pg-1, pg-2, pg-3; Index Scan Backward 4.1 ms and 0.06 ms |
  | 6 verify, 150 req/s 5 m | passed; 0 connections waiting in either pool |
  | 7 restore | gone from all three; Parallel Seq Scans again (125 ms, 95 ms) |

- **Runbook 17 done on both engines, repeatably.** Only the latest log per engine is kept (user, 10-28); older and failed logs deleted.

## 2026-10-28: runbook 17 on MySQL passed (repeatable version); restart notes; shutdown fix

- **Restart after the battery swap (21:47):** Galera 3 Synced through crash recovery; relational 44/45, platform 12/13. The one missing scrape was an orders-mysql pod restarting until MySQL was back; fine minutes later.
  - **PostgreSQL failed over during the cold start:** CloudNativePG at 21:51:38, "Current primary isn't healthy, initiating a failover from pg-2 to pg-1". The cluster stayed healthy, both replicas streaming. Earlier restarts did not do this: a timing race. Follow-up: a small `failoverDelay`, so a primary that is only starting keeps its role.
- **Run `runbook-17-mysql-20261028-215757.txt` (committed log), 3.0 million orders, pxc-0 the writer:**

  | step | result |
  |---|---|
  | 0 | the leftover index dropped in about 1 s (`ALGORITHM=INPLACE`, no LOCK clause) |
  | 1 before | table scans of 3.01 million rows: 996 ms (status), 590 ms (30 days) |
  | 3 change | pt-osc `--chunk-time 0.1`: dry run 1 s, copy 1 min 34 s (21:59:06-22:00:40), swap 1 s |
  | 4 during (20 req/s) | 6,287 writes succeeded, **0 failed**, 0 lost. Writer-pool wait max 0.37 s (3.0 s with 0.5 s chunks). 9 Galera certification failures on pxc-0, absorbed by the app's retries |
  | 5 after | index on all 3 nodes; index lookups 2.05 ms and 0.34 ms |
  | 6 verify, 150 req/s 5 m | passed: search p95 2.64 ms, create 3.87, update 3.56, delete 3.06, read 1.18 ms; 0 errors; 0 connections waiting in either pool (runbook 40's Verify on MySQL) |
  | 7 restore | index gone from all 3 nodes; table scans again (673 ms, 644 ms) |

- **Memory:** peak 1,702 MiB on pxc-0 of 2,048 (17% headroom, less than the 25% estimated); pxc-1 1,542, pxc-2 1,555. Watch it; next lever is a smaller pinned buffer pool.
- **`docker_shutdown.sh` fixed:** a node that will not stop is tried once more; if it still runs, the script exits 1 and leaves Docker Desktop running instead of killing it. Tested against a fake `docker` whose worker3 never stops: retried, reported, exit 1, Docker Desktop never quit.
- **Writes slowed during the copy, none failed:** the background load's write p95 was 15-20 ms (about 3 ms without the copy), max 1.56-1.8 s. Its k6 summary said FAILED, for search only: slow until the index existed. The script now labels that block as not judged.
- **Shutdown 22:3x:** `docker_shutdown.sh` (the fixed version) stopped all four nodes cleanly, then quit Docker Desktop.
- **Next:** start with `docker_restart.sh`, rerun runbook 17 on pg with the repeatable version (its index is still in place from 10-27), then commit.

## 2026-10-28: stopped for a laptop battery swap (work uncommitted)

- **Shutdown:** `docker_shutdown.sh` at ~02:45 UTC, at the user's request. worker3 (mysql-pxc-0, the writer, and pg-3) refused to stop ("tried to kill container, but did not receive an exit event"), and the script quit Docker Desktop anyway, which killed it uncleanly.
  - Expect PXC full-cluster crash recovery and pg-3 to catch up on restart.
  - **Script bug to fix:** `docker_shutdown.sh` should stop, and not quit Docker Desktop, when a node does not stop.
- **Resume:** `docker_restart.sh` (13/13 and 45/45 expected), then `runbook_17_index.sh mysql` (step 0 drops the leftover index; the drop's `LOCK=NONE` fix has not run yet), then a `pg` rerun with the repeatable version, then commit.

## 2026-10-28: runbook 17 on MySQL, third try: pt-osc succeeded, script misjudged it; runbook made repeatable

- **Run 02:18 (`-FAILED` log, local):** checks 45/45 first.
  - The pt-osc copy succeeded: 3.1 million rows in 2 min 22 s (02:22:08-02:24:30), swap in 1 s, triggers and old table dropped, index on all three nodes, nothing left behind.
  - Memory as predicted: the pools filled (free 11-16 MB). Peak 1,573 MiB on the writer pxc-0 of 2,048 (23% headroom); 1,343 and 1,513 on the others. No restarts.
- **Script bug:** `pt_osc` waited only 60 s for the Job's verdict after following its log. The log follow had started before the pod and returned at once, so the script declared failure at ~02:23 while the copy ran.
  - The same Ready-wait cost the 3 s dry-run 3 minutes (a finished pod never reports Ready).
  - Fixed: wait for the container to start, follow the log, then wait for the verdict with no cap. `activeDeadlineSeconds` 3600 on the Job bounds it.
- **1 write failed during the copy** (02:23:16): a create got a 503 after a 3.0 s writer-pool wait on one app pod; 1 of 4,779 writes in the run, no lost writes.
  - pt-osc grows chunks until each takes 0.5 s and reads them `LOCK IN SHARE MODE`. App updates to rows in the chunk being copied wait, and Galera recorded 5 certification failures and 6 brute-force aborts. Writer connections held by those waits filled a 10-connection pool for a moment.
  - Within k6's 1% SLO, but the runbook asks for 0. Change: `--chunk-time 0.1`, so about a fifth of the rows are locked at a time.
- **Repeatable runbook (user's request):** a lab runbook should leave the cluster as it found it.
  - Step 0 now drops an index left by an earlier run, so every run starts from the planted problem. Step 7 drops the index again after the verify and confirms the plans scan again; it runs even when the verify fails. `--keep` leaves the fix.
  - Drops: PostgreSQL `DROP INDEX CONCURRENTLY`; MySQL an in-place `DROP INDEX` (metadata only; Galera TOI, 5 s lock wait, retried). PXC refuses `LOCK=NONE` for it (error 1845, "Try LOCK=SHARED"; the first try of the drop failed on it), so no LOCK clause.
  - The PostgreSQL index from the 23:20 run is still in place; the next pg run drops it first.

## 2026-10-28: runbook 17 on MySQL found the PXC memory trap; nodes at 2Gi, buffer pool pinned

- **First MySQL try (23:32):** failed safely in the pt-osc `--dry-run`. The script's `COLUMNS` variable is bash's terminal width, reset after each command when run from a terminal: the ALTER read `ADD INDEX ... (102)`. Renamed `INDEX_COLUMNS`. The PostgreSQL run had no terminal, so it was unaffected.
  - The dry-run still proved the setup: root through the Secret-built defaults file, TLS through HAProxy, pt-osc's PXC checks, scratch table cleaned up.
- **Second try (23:35):** pt-osc copied 66% of 3.1 million rows (chunks grown to ~23,500 rows), then lost its connection at 23:38:32: **the writer mysql-pxc-0 was OOMKilled at 23:38:20**.
  - pt-osc removed its triggers and copy; `orders` was not altered. HAProxy moved the writer, and pxc-0 rejoined.
  - The k6 load at 20 requests/s saw 22 of 9,159 requests fail (17 creates, 2 updates, 3 reads): a real unplanned failover. No acknowledged write was lost.
- **Cause: the buffer pool fills only when used.** The operator sets `innodb_buffer_pool_size` to half the limit (768M of 1536Mi).
  - Before the copy each pool was about half used (~360 MB free); the copy filled it on every node within a minute (free 9 MB). Memory on pxc-0 went 1,153 to 1,520 MiB.
  - mysqld needs the pool plus about 760 MB (total minus pool, the same at both times). So 1536Mi had no headroom once the pool filled; the spare ~380 MiB seen until then was the empty half of the pool.
  - Galera queues were small (receive queue at most 32, certification index ~150k keys): not the cause.
  - The earlier seed peak (1,131 MiB) never filled the pool. Any whole-table job (index build, backup, report) would have done this.
- **Fix (user's choice of three), applied 01:27-01:29 UTC:** memory 2Gi and `innodb_buffer_pool_size=768M`, pinned (the module's new `innodb_buffer_pool_size` variable, rendered into the mysqld config). Expected peak ~1.53 GB of 2 GB (25% headroom).
  - Rolling restart: pxc-2, pxc-1, then the writer pxc-0. All three Synced with a 768 MB pool.
  - Mid-rollout, checks showed 41/45 (cluster initializing; `mysql_up` counted twice while the restarted node's old-IP series expired).

## 2026-10-27: runbook 17 on PostgreSQL passed (the missing index, online); runbook logs

- **Runbook logs:** `runbook_log` in `scripts/private_env.sh` copies a script's output to `<category>/logs/<name>-<UTC time>.txt`.
  - A successful run keeps its log, to commit. A failed run's log becomes `-FAILED.txt`, which git ignores.
  - A load test called from a runbook writes into the runbook's log. Two runs in the same second get separate files.
  - All of this was tested with a scratch script.
- **`relational/scripts/runbook_17_index.sh pg|mysql`:**
  1. Before plans.
  2. k6 at 20 requests/s.
  3. Adds `orders_customer_created_idx (customer_id, created_at, id)`: `CREATE INDEX CONCURRENTLY` with `lock_timeout` 5 s, and an INVALID leftover is dropped and the build retried. PXC uses pt-online-schema-change 3.7.1 as a Job, pausing on flow control.
  4. Write failures and lost writes from k6 in Prometheus; the change must end before the load does.
  5. The index on every node, and the plans after.
  6. 150 requests/s for 5 m, every SLO.
  - One index for both search shapes: each filters one customer and wants the newest 20.
- **PostgreSQL run** (`relational/logs/runbook-17-pg-20261027-232010.txt`), 3.0 million orders. Claude started it while meaning to test only the script's Docker-down path; Docker was already back up.

  | | before | after |
  |---|---|---|
  | Search plan (pg-1) | Parallel Seq Scan: 151 ms (status), 63 ms (30 days) | Index Scan Backward: 0.48 ms, 0.11 ms |
  | Index build | | 2 s, first attempt |
  | Writes during the change | | 1,720 succeeded, 0 failed, 0 lost |
  | 150 requests/s, 5 m | FAILED: search p95 4.43 s, 26.9% errors | passed: search p95 2.03 ms, 0 errors |
  | create / read / update p95 | 60 / 30 / 58 ms | 2.2 / 0.67 / 1.72 ms |
  | Max waiting, reader / writer pool | 52 / 0 | 0 / 0 |

  - That is also runbook 40's full Verify. Writes got faster too: the scans had been taking the CPU.
- **Next:** `runbook_17_index.sh mysql` (pt-online-schema-change, about 20 minutes).
- **Not changed:** Flyway still creates the schema without the index, so a new cluster keeps the planted problem for runbooks 2 and 17.

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
