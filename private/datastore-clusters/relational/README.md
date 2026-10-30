# relational

Two 3-node highly available SQL clusters, one node per zone, that keep
serving writes with any one zone down and lose no committed data. The
private-cloud version of an Aurora design (two Aurora clusters), which the
AWS Free plan can't run.

| Example | Cluster | Engine | Nodes | Writer / reader endpoints |
|---|---|---|---|---|
| `modules/postgresql` | `pg` | PostgreSQL 16.13 (deliberately old: see the runbooks), CloudNativePG 1.30.1 | 1 primary + 2 streaming replicas | `pg-rw` / `pg-ro` |
| `modules/mysql` | `mysql` | Percona XtraDB Cluster 8.0.44 (MySQL 8.0, past upstream end of life; Galera), Percona operator 1.20.0 | 3 Galera nodes + 3 HAProxies | `mysql-haproxy` / `mysql-haproxy-replicas` |
| distributed SQL (planned) | | YugabyteDB or TiDB | Raft groups across 3 zones | |

Both run in namespace `relational`. The endpoints are Kubernetes Services
(`<name>.relational.svc`) that follow the writer on failover: the service
discovery that Aurora's cluster endpoint provides.

## How each survives losing a zone

| | PostgreSQL (CloudNativePG) | MySQL (Percona XtraDB Cluster) |
|---|---|---|
| Copies of the data | 3, one per zone | 3, one per zone |
| A commit waits for | the primary + **any 1** of the 2 replicas (quorum synchronous replication) | a **majority** (2 of 3) of nodes to certify it (Galera) |
| One zone down | a replica is promoted (only one known to hold every commit: `failoverQuorum`); writes resume on `pg-rw` | the other 2 nodes are still a majority; HAProxy moves writes to one of them |
| Two zones down | writes stop rather than risk losing data (`dataDurability: required`) | the last node is a minority and stops accepting writes |
| Planned maintenance | PodDisruptionBudget: one instance down at a time | PodDisruptionBudget: one node down at a time |

Aurora does the same with six storage copies across three AZs (write
quorum 4 of 6).

## Layout

| Path | Creates |
|---|---|
| `modules/postgresql/operator/` | CloudNativePG (Helm, namespace `cnpg-system`, watches every namespace), its PodMonitor and the official CloudNativePG Grafana dashboard |
| `modules/postgresql/cluster/` | One `Cluster`: required zone anti-affinity, quorum sync replication, TLS-only `pg_hba`, PDB, app database and role; apply waits for Ready. `monitoring.tf`: PodMonitor for every instance |
| `modules/mysql/operator/` | Percona PXC operator (Helm, namespace `pxc-operator`, watches every namespace) |
| `modules/mysql/cluster/` | One `PerconaXtraDBCluster`: zone anti-affinity, HAProxy, TLS for clients and replication, `require_secure_transport`, PDBs, app database and user; apply waits for ready. `monitoring.tf`: `mysqld_exporter` sidecar per node, PodMonitor, and the MySQL / Galera dashboard (`dashboards/mysql-galera.json`) |
| `environments/dev/operators/` | Both operators |
| `environments/dev/clusters/` | Namespace `relational`, `pg` and `mysql` (versions in `variables.tf`) |
| `modules/orders-app/` | The example app for one engine: Deployment (2 pods across zones), Service, ServiceMonitor |
| `environments/dev/app/` | The orders app for both engines, its k6 script and the Orders load dashboard (source, tests and the load: [app/README.md](app/README.md)) |
| `scripts/check_resources.sh` | Read-only PASS/FAIL, including SQL through each endpoint and refused plaintext; the app once deployed |
| `scripts/build_app.sh [--test]` | Build the orders image and load it into the kind nodes |
| `scripts/load_test.sh pg\|mysql seed\|run` | Run the k6 load as a Job; results in Grafana |
| `scripts/runbook_1_alerts.sh pg\|mysql [rate] [duration]` | Runbook 1, repeatable: under k6 load, fires member down, replication lag, connections over 80% and the search latency SLO on purpose, checks each reaches Alertmanager and clears, and undoes every trigger (also on failure) |
| `scripts/runbook_13_patch.sh pg\|mysql [rate] [duration]` | Runbook 13, repeatable with a new target: patches every member to the minor version set in `environments/dev/clusters/variables.tf` under k6 load (you apply the clusters root when it asks), times each member and the writer's move, checks each server's own version; at most 30 s of app errors, no acknowledged write lost, nothing failing after the rollout. MySQL 8.0 only moves forward |
| `scripts/runbook_17_index.sh [--keep] pg\|mysql [rate] [duration]` | Runbook 17, repeatable: adds the missing search index online under k6 load (PostgreSQL `CREATE INDEX CONCURRENTLY`; PXC pt-online-schema-change), proves no write failed, verifies every SLO at 150 requests/s, then drops the index again so the next run starts from the planted problem (`--keep` leaves it) |
| `scripts/runbook_24_writer.sh pg\|mysql [rate] [duration]` | Runbook 24, repeatable: kills the writer's pod under k6 load (via `failover_test.sh`), then proves the database's and the app's outages are each within the 60 s RTO, no acknowledged write was lost, the app's writes all succeed once the writer is back, the old writer rejoined, and the relational check passes |
| `scripts/runbook_23_switchover.sh pg\|mysql [rate] [duration]` | Runbook 23, repeatable: moves the writer on purpose under k6 load (PostgreSQL: CloudNativePG switchover to a replica; PXC: `pxc_maint_mode=MAINTENANCE` so HAProxy moves writes), checks writes succeed on the new writer, then moves it back; no write lost, one writer, the original |
| `scripts/runbook_25_reader.sh pg\|mysql [rate] [duration]` | Runbook 25, repeatable: deletes a replica's pod under k6 load; no write may fail or be lost, reads must all succeed once it is back; reports how long it took to rejoin and catch up |
| `scripts/runbook_lib.sh` | Shared by the runbook scripts: log, cluster health, the background k6 load and its results in Prometheus, the final check |
| `logs/` | The latest run of each runbook per engine (`runbook-<n>-<engine>-<time>.txt`); a pass replaces the older logs; a failed run stays local as `-FAILED.txt` (only the newest) |
| `scripts/runbook_26_zone.sh pg\|mysql [rate] [duration]` | Runbook 26, repeatable: stops the writer's zone under k6 load (k6 runs outside it), then proves the database's and the app's outages are each within the 60 s RTO, no acknowledged write was lost, no request failed after recovery, and the zone rejoined |
| `scripts/failover_test.sh pg\|mysql [pod\|zone]` | Takes out the writer (its pod, or its whole zone with `docker stop`) under a write probe; reports the outage and, for a zone, the time to heal. Passes when writes recover, with a new writer or the same one back (a PostgreSQL primary back within `failoverDelay` keeps its role) |

## Build and tear down

The platform (`../platform`) first. Then, from the repo root:

```sh
cd private/datastore-clusters/relational/environments/dev/operators
terraform init && terraform plan -out plan-operators && terraform apply plan-operators   # ~1 min

cd ../clusters
terraform init && terraform plan -out plan-clusters && terraform apply plan-clusters      # ~5-10 min: image pulls, then 3 nodes each

../../../scripts/check_resources.sh
../../../scripts/failover_test.sh pg            # delete the primary's pod; measure the write outage
../../../scripts/failover_test.sh mysql zone    # stop the writer's whole zone; measure, then heal
```

Then the example app and its load: [app/README.md](app/README.md).

Tear down the app, then clusters, then operators (each `plan -destroy -out plan-destroy-<root>`,
then apply that plan). Memory while up: about 5 GB of the Docker Desktop VM.

## Metrics and dashboards

Both engines report to the shared Prometheus (`../platform`, namespace
`monitoring`); Grafana loads their dashboards automatically.

| | PostgreSQL | MySQL |
|---|---|---|
| Exporter | built into every CloudNativePG instance (port 9187) | `mysqld_exporter` sidecar on every PXC node (port 9104), logged in as the operator's `monitor` user over the local socket |
| Grafana dashboard | **CloudNativePG** (official, shipped with the operator chart) | **MySQL / Galera (Percona XtraDB Cluster)** (`modules/mysql/cluster/dashboards/mysql-galera.json`) |
| Shows | replication lag, WAL and checkpoints, connections, locks, database size, operator health | Galera membership and flow control, CRUDS by statement type, connections against `max_connections`, slow queries, full scans, top statements and statements without an index, buffer pool, memory against the limit |

Changing the MySQL cluster's sidecar restarts its nodes one at a time
(the operator's SmartUpdate), so the cluster stays writable. `terraform
apply` returns before that restart starts: its wait (`status.state =
ready`) is already true when the change lands. Wait for the rollout before
running the checks:
`kubectl -n relational get pxc mysql -w` until `ready` again (about a
minute per node). Query-level
statistics for PostgreSQL (`pg_stat_statements`) come with runbook 2.

## Connecting

The databases are reachable only inside the cluster. From the laptop,
forward a port (this shell only):

```sh
export KUBECONFIG=~/.kube/kind-datastore-dev
kubectl -n relational port-forward svc/pg-rw 5432:5432 &
PGPASSWORD="$(kubectl -n relational get secret pg-app -o jsonpath='{.data.password}' | base64 -d)" \
  psql "host=127.0.0.1 user=app dbname=appdb sslmode=require"

kubectl -n relational port-forward svc/mysql-haproxy 3306:3306 &
MYSQL_PWD="$(kubectl -n relational get secret mysql-secrets -o jsonpath='{.data.root}' | base64 -d)" \
  mysql -h 127.0.0.1 -uroot --ssl-mode=REQUIRED
```

Unencrypted connections are refused by both (`hostnossl ... reject` in
`pg_hba`, `require_secure_transport=ON`).

## Version path (for the patch and upgrade runbooks)

| | Start | Security patch | Major upgrade |
|---|---|---|---|
| PostgreSQL | 16.13 | 16.15, replicas first, then a switchover | 18, in place with `pg_upgrade` (offline; images must share a Debian release, trixie), after a backup; compare with blue/green by logical replication |
| MySQL | 8.0.44 | 8.0.45 (the version operator 1.20.0 tested), one node at a time | 8.4.8: Percona's recommended operator path, a new 8.4 cluster seeded from backup plus asynchronous replication, then cut over |

MySQL-specific "force an election": Galera has no elected leader; the
emergency is a cluster that lost its majority. The drill forces the survivor
to become the Primary Component (`pc.bootstrap`), accepting the loss of
anything only the failed nodes had.
