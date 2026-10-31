# Test plans

What each scripted runbook does, what it must show to pass, and what the
lab measured, so the expectations outlive the logs and the chat. The runbooks
themselves (goal, procedure, every engine) are in
[../docs/RUNBOOKS.md](../docs/RUNBOOKS.md); the scripts are in
[../relational/scripts/](../relational/scripts/); each run's log is in
[../relational/logs/](../relational/logs/).

| Plan | Runbook | Script | Changes the cluster | Latest pass |
|---|---|---|---|---|
| [runbook-01-alerts.md](runbook-01-alerts.md) | 1. Monitor | `runbook_1_alerts.sh` | no (every trigger undone) | 2026-10-30, both |
| [runbook-05-load.md](runbook-05-load.md) | 5. Load test | `load_test.sh` | no (adds rows) | 2026-10-29, pg |
| [runbook-13-patch.md](runbook-13-patch.md) | 13. Security patch (minor version) | `runbook_13_patch.sh` | yes: new image, writer moves | 2026-10-30, both |
| [runbook-17-index.md](runbook-17-index.md) | 17. Schema migration (online index) | `runbook_17_index.sh` | no (index dropped again) | 2026-10-28, both |
| [runbook-23-switchover.md](runbook-23-switchover.md) | 23. Planned switchover | `runbook_23_switchover.sh` | no (writer moved back) | 2026-10-30, both |
| [runbook-24-writer.md](runbook-24-writer.md) | 24. Writer failure | `runbook_24_writer.sh` | yes: writer usually moves | 2026-10-30, both |
| [runbook-25-reader.md](runbook-25-reader.md) | 25. Reader failure | `runbook_25_reader.sh` | no | 2026-10-30, both |
| [runbook-26-zone.md](runbook-26-zone.md) | 26. Zone outage | `runbook_26_zone.sh` | yes: writer usually moves | 2026-10-30, both (worst case) |

The other runbooks in RUNBOOKS.md (backups, restore, major upgrade, quorum
loss, and the rest) are not scripted yet; they get a plan here when they are.

## The lab

- kind cluster `datastore-dev` (kubeconfig `~/.kube/kind-datastore-dev`):
  1 control plane and 3 workers labelled zones `dc1-a`, `dc1-b`, `dc1-c`. A
  zone outage is `docker stop` of a worker container.
- `pg`: CloudNativePG, 3 instances (1 primary, 2 replicas, quorum commit ANY
  1 of 2), `primaryUpdateMethod: switchover`, failoverDelay 5 s.
- `mysql`: Percona XtraDB Cluster, 3 Galera nodes plus 3 HAProxy; HAProxy
  sends writes to one node.
- Operators: 2 copies each, in different zones (required anti-affinity),
  one leading on a 15 s lease.
- App: `orders-pg` and `orders-mysql`, 2 pods each, 768Mi, JVM heap 50%.
  Retries: 4 attempts, backoff 0.1/0.2/0.4 s, 3 s pool connect timeout,
  then 503 (about 13 s in all).
- Data: both engines seeded to ~3,000,000 orders. MySQL keeps the planted
  missing index (runbook 17), so its search misses the SLO by design.
- Node failure detection: kube-controller-manager node-monitor-grace-period
  20 s (default 40 s).

## Rules that apply to every plan

- **Preconditions:** the cluster is whole (3 members, replicating) and
  `relational/scripts/check_resources.sh` passes (50/50) before a run.
- **Load:** k6 as a Job in the cluster (`app/k6/orders.js`), default 20
  requests/s. Mix: create 20%, read 45%, search 20%, update 10%, delete 5%.
  SLO per operation: p95 create/update/delete 200 ms, read 100 ms, search
  300 ms; at most 1% failed each; `orders_lost` 0. Each request times out at
  15 s (above the app's ~13 s retry budget, so k6 sees the app's answer, not
  its own wait).
- **RPO 0:** no acknowledged write is ever lost (k6 reads back every order it
  created and counts any missing in `orders_lost`).
- **SETTLE 30 s:** after the event ends (writer back, replica back, zone
  back), no write or read may fail from 30 s on.
- **The search SLO is not judged** on runs that are not about it: it fails
  on mysql by design while the planted index is missing.
- **Verify:** every run ends with `check_resources.sh` passing.
- **Logs:** `relational/logs/runbook-<n>-<engine>-<time>.txt`; a failed run
  writes `-FAILED.txt` (not committed). A pass replaces older logs of the
  same runbook and engine.
- **The app's pods:** select them with `app.kubernetes.io/name=orders` and
  the instance label; k6's job pods share the instance label (`APP_PODS` in
  `runbook_lib.sh`).

## Known issues seen across runs

- When an app pod's node comes back (runbook 26), the pod exits 1 twice on
  startup because it can't reach the database yet, then starts. It shows as
  2 app restarts per run; not a failure, not fixed yet.
