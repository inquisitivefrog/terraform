# private: status

Rolling record for the private cloud (Docker Desktop + kind on the laptop).
Newest first.

## Current state (2026-10-26): platform and relational applied

kind cluster `datastore-dev` (4 nodes, zones dc1-a/b/c) with
kube-prometheus-stack; CloudNativePG and Percona PXC operators; `pg`
(PostgreSQL 16.13, 3 instances) and `mysql` (PXC 8.0.44, 3 nodes + 3
HAProxies) in namespace `relational`. Verified: platform check 13/13
(including monitoring), relational check 29/29. Disk blocker cleared (65 GB free); Docker
Desktop at 14 GB memory, 8 CPUs.

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
