# private/datastore-clusters

The whole range of datastore categories, each with two or three
representative engines, run the way a team would run them itself: on a
3-zone private cloud, through operators, with runbooks for the work that
follows "it's deployed". Built on the laptop (Docker Desktop + kind) because
the same designs in AWS cost more than the Free plan allows.

Why it is shaped this way, and what was decided: [docs/DESIGN.md](docs/DESIGN.md).
How backups work (the store, cert-manager, the Barman Cloud plugin,
XtraBackup), piece by piece: [docs/BACKUPS.md](docs/BACKUPS.md). What each
scripted runbook must show: [test_plans/](test_plans/README.md).

```
datastore-clusters/
  platform/                  shared: 3-zone kind cluster; services (Prometheus + Grafana, cert-manager); backup store (outside the cluster)
  <category>/
    modules/<engine>/operator   the engine's control plane (Helm)
    modules/<engine>/cluster    one HA cluster of it (custom resource)
    environments/dev/operators  root 1: install the operators
    environments/dev/clusters   root 2: the clusters (needs root 1's CRDs to plan)
    app/                        example CRUD app for the category's engines, plus its k6 load test (planned)
    scripts/                    check_resources.sh and the runbooks
```

One category runs at a time on the shared platform: apply it, run its
checks and runbooks, destroy it, move on. Each category uses its own
namespace, named after it.

## Categories

Engines chosen for an open licence, arm64 images and a maintained operator
or chart; each is re-verified when its category is built.

| Category | Examples | Status |
|---|---|---|
| [relational](relational/README.md) | PostgreSQL (CloudNativePG), MySQL (Percona XtraDB Cluster), distributed SQL (YugabyteDB or TiDB) | PostgreSQL and MySQL written, not applied |
| in-memory | Valkey (open fork of Redis), Redis 8 (AGPL again since 2025), Memcached | planned |
| search / index | OpenSearch, Elasticsearch (ECK), Solr | planned |
| time-series | Prometheus + Thanos or Mimir, VictoriaMetrics, InfluxDB 3 | planned (Prometheus arrives with the monitoring runbook) |
| NoSQL (wide-column, document) | Cassandra (K8ssandra), MongoDB (Percona operator; SSPL licence) or FerretDB, CouchDB | planned |
| vector | pgvector (on CloudNativePG), Milvus, Qdrant | planned |
| graph | Neo4j Community, Apache AGE (PostgreSQL extension), JanusGraph (on Cassandra) | planned |
| large volume (object storage, analytics) | Garage, SeaweedFS, ClickHouse | planned (the object store arrives with the backup runbook) |
| directory | OpenLDAP (multi-provider), 389 Directory Server | planned |
| streaming log (event store) | Kafka (Strimzi), NATS JetStream | candidate: not a database, but stores data and needs the same runbooks |

Two choices that run through all of them:

- **Add an engine only for a measured need.** Every engine multiplies the
  runbooks below and the on-call knowledge. PostgreSQL alone covers
  documents (JSONB), time-series (TimescaleDB), vectors (pgvector), graphs
  (AGE) and full-text search; the categories show when a specialised engine
  is worth it.
- **Shared-nothing or disaggregated?** Engines that keep data on local disk
  (PostgreSQL, MySQL, Cassandra, OpenSearch hot nodes) want dedicated nodes,
  local NVMe, replication instead of RAID, and N+2. Engines built on object
  storage (Milvus, InfluxDB 3, Thanos/Mimir, ClickHouse with S3) make nodes
  disposable; the design work moves to the object store and caches.

## Runbooks

The work after "it's deployed", defined once for every engine in
[docs/RUNBOOKS.md](docs/RUNBOOKS.md): 40 runbooks in five groups (observe,
protect, change, recover, secure), a common template (goal, when, before,
steps, verify, roll back, measure), the capacity and storage practices they
enforce, and a symptom-to-runbook table of common problems. Each is scripted
per category and run under the category's k6 CRUDS load.

Built first, in this order: monitor, back up, security patch, tune
configuration, replace a damaged node, force an election, then the major
upgrade last.

## Rules

- Each engine is pinned (chart, image) and starts on an older, supported
  version where the patch and upgrade runbooks need one.
- Passwords come from the operators into Kubernetes Secrets: never in
  Terraform state, never printed, passed to clients on stdin.
- Every client connection uses TLS; plaintext is checked to be refused.
- Scripts and Terraform name the kubeconfig file and context explicitly:
  `~/.kube/config` (and grid-meter's context) is never used or changed.

## Platform

| Path | Creates |
|---|---|
| `platform/modules/kind-cluster/` | One kind cluster: a control plane and one worker per zone, labelled `topology.kubernetes.io/region` and `zone` |
| `platform/modules/monitoring/` | kube-prometheus-stack: Prometheus, Grafana, Alertmanager; picks up monitors, rules and dashboards from every namespace; remote-write receiver for k6 |
| `platform/modules/cert-manager/` | cert-manager: TLS certificates from Certificate and Issuer resources; the Barman Cloud plugin needs it ([docs/BACKUPS.md](docs/BACKUPS.md)) |
| `platform/environments/dev/cluster/` | kind cluster `datastore-dev`, zones `dc1-a`, `dc1-b`, `dc1-c`; kubeconfig `~/.kube/kind-datastore-dev`; local state (every other root reads it) |
| `platform/environments/dev/services/` | Shared services: monitoring (namespace `monitoring`), cert-manager (namespace `cert-manager`) |
| `platform/modules/backup-store/` | SeaweedFS (S3-compatible, `weed mini`) in a Docker container outside the cluster; data on a Docker volume; S3 on 127.0.0.1 only |
| `platform/environments/dev/backup-store/` | Store `datastore-backups`: buckets `pg-backups` and `mysql-backups`, one key each limited to its bucket; laptop `http://localhost:8333`, pods `http://host.docker.internal:8333`. Its own root, so backups outlive a cluster rebuild |
| `platform/scripts/backup_store_keys.sh` | Writes the store's keys to `~/.config/datastore-dev/backup-store/s3.json` (mode 600, outside the repo, never in state); `--rotate` replaces them |
| `platform/scripts/check_resources.sh` | Nodes, zones, taints, localhost-only API, storage class; monitoring; the backup store (running, localhost only, each key only its own bucket, no anonymous access) |
| `platform/scripts/kube_use.sh` | Nodes, Helm releases, and every datastore pod with its zone |

Free at least 40 GB on the Mac's disk, start Docker Desktop with **12-14 GB
memory and 8 CPUs** (Settings > Resources), then from the repo root:

```sh
cd private/datastore-clusters/platform/environments/dev/cluster
terraform init && terraform plan -out plan-cluster && terraform apply plan-cluster     # ~1 min
../../../scripts/check_resources.sh

cd ../services
terraform init && terraform plan -out plan-services && terraform apply plan-services  # ~3 min

# The backup store (outside the cluster; keep it across cluster rebuilds):
../../../scripts/backup_store_keys.sh
cd ../backup-store
terraform init && terraform plan -out plan-backup-store && terraform apply plan-backup-store
../../../scripts/check_resources.sh

# Grafana (this shell only):
export KUBECONFIG=~/.kube/kind-datastore-dev
kubectl -n monitoring get secret kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80   # http://localhost:3000, user admin
```

Then a category, for example [relational](relational/README.md). Tear down
in reverse: the category's clusters, its operators, then the platform's
services and cluster; leave the backup store unless you mean to delete
every backup
(`terraform plan -destroy -out plan-destroy-<root>`, then apply that plan).
Destroying the platform cluster alone deletes everything, but leaves the category
roots with state for resources that no longer exist; delete their
`terraform.tfstate` if you take that shortcut.

Cost: none.
