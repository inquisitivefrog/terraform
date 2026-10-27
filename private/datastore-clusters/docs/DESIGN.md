# datastore-clusters: design notes and decisions

What was discussed while designing this tree (2026-10-24 to 2026-10-26), what
was concluded, and why. The README says what exists; this says why it is
shaped this way. Newest decisions are folded into each section; open
questions are at the end.

## 1. Why a private cloud

The AWS version (two 3-node Aurora clusters) was written first; it was
removed from the repo on 2026-10-26, and its design is recorded in
`aws/tfstate/docs/STATUS.md` (2026-10-24 entries). The account's Free plan rejected it: no Aurora MySQL, and
Aurora PostgreSQL only as a single-writer serverless "express" cluster with
no VPC or customer-managed key. A paid plan isn't affordable for a demo.

**Decision:** build designs first on a laptop private cloud (`private/`):
Docker Desktop + kind, one "data center" (`dc1`) split into three zones, one
Kubernetes worker per zone. It costs nothing and still shows zones, quorum,
failover and node replacement. Cloud versions follow when worth paying for.

## 2. Versions: stay current, upgrade routinely

Observed in past jobs: teams sat on barely supported versions, used only a
minimal feature set ("sorted tables go here"), then panicked when end of
life forced an upgrade across several versions at once.

Why it happens: upgrades that succeed earn no credit, broken ones are
remembered; split ownership (platform team owns the version, app teams own
the risk); no rehearsal environment or tests against the real engine;
portability fears and ORMs pushing a lowest-common-denominator schema; and
schema churn done as risky big-bang migrations.

**Conclusions (current practice):**
- Stay on a supported major, preferably the current or previous one; take
  minors automatically; make major upgrades a routine, rehearsed procedure.
- Rehearse on a clone: restore or clone production, upgrade it, run tests
  and replayed queries, then cut over (Aurora Blue/Green, logical
  replication, operator-driven upgrades).
- Change schemas by expand/contract with online DDL; then using an engine's
  features is no longer risky.
- Use the features that replace application code (JSONB, partitioning,
  row-level security, logical replication, pgvector; window functions and
  CTEs in MySQL 8).
- Licences are part of the version choice: Redis moved off open source in
  2024 (Valkey forked; Redis 8 added AGPL in 2025); Elasticsearch forked to
  OpenSearch (Elastic later added AGPL); MinIO's community edition stopped
  publishing images in October 2025 and is unmaintained.

**Decision:** clusters start on older, still-deployed versions on purpose
(PostgreSQL 16.13, MySQL/PXC 8.0.44, past MySQL 8.0's end of life) so the
patch and upgrade runbooks are real.

## 3. The data-access layer ("DAO, just in case")

A coworker's DAO "in case we switch databases" was rightly laughed at: teams
almost never switch engines, and when they do, SQL, transactions and engine
features leak through anyway. (The thing that actually changed was the
language, Python to Java, which a DAO doesn't help with.)

**Conclusion:** keep a thin data-access layer for the real reasons: one place
for queries and tuning, read/write routing to reader and writer endpoints,
caching, retries across failover, and testing business logic without a
database. Write engine-specific SQL; test the layer against the real engine
and version (Testcontainers), not mocks or SQLite.

**Decision:** each category's example app has a repository layer that speaks
all of the category's engines; there, swapping engines is the point.

## 4. Where a datastore should run

Questions raised: raw disk vs VM vs container; noisy neighbours on shared
physical servers; local disk (spindles, controllers, filesystem layout,
RAID 10) vs network storage; N+2 so nodes can be removed and replaced.

**Conclusions:**
- "Databases on VMs, apps in containers" was right for its time (about
  2015-2021), for operational reasons, not performance. Kubernetes storage
  and operators were immature, pods were rescheduled freely, and per-core
  licences (SQL Server, Oracle) pushed engines onto dedicated hosts.
- Container overhead is close to zero (a process under cgroups); a VM adds a
  hypervisor. What decides performance is the storage path, noisy
  neighbours, CPU/NUMA placement and memory sizing.
- Most applications hit query, index, N+1 and connection-count problems long
  before hardware limits. Truly performance-critical needs are settled by
  choosing the right engine in a proof of concept, not the hosting layer.
- Current order of preference: (1) a managed service; (2) Kubernetes with a
  mature operator, done properly (dedicated tainted node pools, Guaranteed
  QoS, zone anti-affinity, PodDisruptionBudgets, fast local or CSI storage);
  (3) VMs or bare metal for very large datasets (hours to re-clone),
  per-core licensing, kernel tuning, or a team without Kubernetes skills.
- Noisy neighbours are real. Isolation from weakest to strongest: shared VM,
  VM on a dedicated host, bare-metal instance, own server. On Kubernetes:
  dedicated node pools sized to fill a machine plus the CPU Manager static
  policy. Each step costs utilisation and replacement speed.
- Local NVMe beats network block storage for heavy-I/O shared-nothing
  engines (about 0.1 ms vs 0.5-1 ms). NVMe ended spindle management, and a
  hardware RAID card is often the bottleneck. RAID 10 is the fastest
  redundant RAID level (RAID 5/6 are slower on writes); the trend is no RAID
  or software RAID, with redundancy moved up to replicas across nodes and
  zones: a dead disk is a dead node, replaced and re-cloned.
- Filesystem layout still matters for new reasons: XFS or ext4, `noatime`,
  aligned partitions, the `none` I/O scheduler for NVMe; WAL on its own
  volume (different write pattern; a runaway WAL can't fill the data
  volume).
- N+2 is the honest version of N+1: with three nodes, maintenance leaves no
  spare. Quorum systems want odd counts (5 tolerates 2 failures; 4 only 1).

### Storage media, capacity and shared disks (discussed 2026-10-26)

Points raised from past operation (separate index and data logs, filesystem
choice and reformatting to change defaults, write-cache cards, renaming files
on bad blocks, journaling, snapshots, SSDs "great for caching but bad at
random access"), mapped to current practice. Details live in
[RUNBOOKS.md](RUNBOOKS.md) (storage practices and capacity rules).

- **Interfaces.** SCSI became SAS and ATA became SATA, both designed around
  a disk head. NVMe (Non-Volatile Memory Express) is the flash-native
  interface on PCIe: no controller in the path, up to 64K queues (one per
  core), about 7-14 GB/s and around 10-20 microseconds per I/O. SSD vs HDD
  is the medium; NVMe vs SAS vs SATA is the interface; NVMe SSDs are the
  standard for fast storage, SAS/SATA hard disks for cheap capacity. NVMe
  over Fabrics carries the same protocol over the network (cloud block
  storage, including EBS, appears as NVMe).
- **SSDs and random I/O.** Random reads were always SSDs' strength; the
  early weakness was random writes (erase blocks larger than pages, write
  amplification, the write cliff when full, no TRIM, wear). Fixed by
  over-provisioning, TRIM, better controllers and rated endurance (drive
  writes per day). Still true: consumer QLC drives fall to hard-disk speed
  once their SLC cache fills; garbage collection shows as tail latency.
  Decision: databases on enterprise TLC mixed-use drives; periodic `fstrim`;
  watch p99.
- **What changed for the old practices.** Index/data separation is now about
  capacity isolation, not seeks; filesystem parameters fixed at mkfs time
  still mean a reformat, done as a rolling member replacement; RAID cards
  became the bottleneck for NVMe, so redundancy moved to replication; BBU
  cache cards became drives with power-loss protection (and their learn
  cycle a classic latency-spike incident); bad-block handling became SMART
  and NVMe health monitoring with replacement before failure; keep metadata
  journaling only (the WAL protects data); snapshots need backup mode or
  `fsfreeze` to be consistent.
- **Capacity.** Enterprise SSDs are 4-15 TB commonly and 30-120+ TB (QLC);
  hard disks about 24-32 TB and still several times cheaper per TB. Tier by
  temperature: NVMe TLC hot, NVMe QLC warm and read-mostly, hard disks for
  backups and archives, tape or archive classes for retention. Decision:
  cap data per node by rebuild time, not drive size (about 1 GB/s re-clone:
  10 TB is ~3 h with a copy missing, 60 TB most of a day); prefer more,
  smaller nodes.
- **Noisy neighbours on big shared disks.** Capacity divides cleanly;
  performance doesn't (one tenant's writes trigger garbage collection that
  stalls the others). Addressed by drive features (NVMe namespaces don't
  isolate performance; NVM Sets and Flexible Data Placement do, but are
  rare outside hyperscalers), by the OS (cgroup v2 `io.max`, `io.weight`,
  `io.cost`; Kubernetes has no disk I/O requests or limits), by storage
  systems (provisioned IOPS on cloud volumes: the "generic rate" is the
  noisy-neighbour fix; Ceph mClock; array QoS; `VolumeAttributesClass`), and
  above all by architecture: whole disks for database members on dedicated
  nodes, write-heavy neighbours kept off database disks. Decision: a
  noisy-neighbour drill (`fio` on a shared disk) is a planted problem in
  runbook 2.

## 5. When no managed service exists

Less common engines (Milvus, InfluxDB, ArcGIS's geodatabase) may have no
cloud offering, and then the team (often a startup) owns the operation.

**Conclusions:** check vendor SaaS first (Zilliz Cloud for Milvus; InfluxDB
Cloud and AWS Timestream for InfluxDB; ArcGIS's geodatabase runs on
PostgreSQL/PostGIS, SQL Server or Oracle, and Esri sells ArcGIS Online and
ArcGIS Enterprise on Kubernetes). If self-hosting, cloud bare-metal or
dedicated hosts give a whole machine without owning hardware. Then decide by
architecture (next section), not habit.

## 6. Categories and the architecture question

The range: directory, relational, NoSQL (wide-column, document, key-value),
time-series, graph, search/index, large volume (object storage,
analytics), vector, in-memory; streaming logs (Kafka) as a near relative.
Each differs in data model, HA model and hosting needs (table in the
README).

**Conclusions:**
- Every engine multiplies the runbooks and on-call knowledge, so add one only
  for a measured need. PostgreSQL alone covers documents, time-series,
  vectors, graphs and full-text search for many startups.
- The deciding question for hosting: **shared-nothing or disaggregated?**
  Shared-nothing engines (PostgreSQL, MySQL, Cassandra, OpenSearch hot
  nodes) keep data on local disk: dedicated nodes, local NVMe, replication
  instead of RAID, N+2. Disaggregated engines (Milvus, InfluxDB 3,
  Thanos/Mimir, ClickHouse on S3, Aurora, Neon) keep durable data in object
  storage: nodes are disposable; design effort goes to the object store and
  caches.

**Decision:** show the whole range: 2-3 engines per category under
`<category>/modules/<engine>/{operator,cluster}`, on one shared platform, one
category running at a time. Engines are chosen for an open licence, arm64
images and a maintained operator, and re-verified when built.

## 7. Runbooks

The work after "it's deployed", defined in [RUNBOOKS.md](RUNBOOKS.md): 39
runbooks with one template, judged under k6 load. The first seven requested,
in build order: monitor, back up, security patch, tune, replace a damaged
node, force an election, major upgrade. Monitoring and backups come first
(watch everything; never change a database without a tested backup); the
major upgrade comes last (afterwards there is nothing old to patch). The
rest were added to cover storage practice and the common incidents
(restore and point-in-time recovery, disk full, replication slots and
lag, split brain, quorum loss, corruption, connection exhaustion, OOM,
clock skew, rotations).

**Capacity in a private cloud.** Public clouds lend capacity on demand
(autoscaling borrows from the provider's pool). A private cloud owns its
pool and hardware takes weeks or months to arrive, so headroom is bought in
advance: N+2 nodes per pool; CPU may be over-subscribed, database memory not
(request = limit), storage never thin-provisioned beyond what is backed;
spare disk and network for re-cloning a replaced node; engine peaks (fork
for snapshots, compaction) budgeted; alerts at 70/80/90% and hardware
ordered when the forecast crosses 80% within the purchase lead time.

Engine-specific findings:
- PostgreSQL major upgrade: CloudNativePG (1.26+) upgrades in place with
  `pg_upgrade` when the image's major changes; offline; old and new images
  must share a Debian release. Alternative: blue/green by logical
  replication.
- MySQL major upgrade with the Percona operator: Percona recommends a new 8.4
  cluster seeded from an 8.0 backup plus asynchronous replication, then a
  cutover, over in-place.
- "Force an election" for Galera: there is no leader; the emergency is a
  lost majority, fixed by forcing a survivor to be the Primary Component
  (`pc.bootstrap`), accepting loss of anything only the failed nodes had.

## 8. Observability and load

**Decisions:**
- Prometheus + Grafana (kube-prometheus-stack) are platform services shared
  by all categories. Each category ships its own ServiceMonitors/PodMonitors,
  alert rules and dashboards (ConfigMaps labelled `grafana_dashboard=1`).
- Each category gets an example app: a small HTTP CRUD service whose
  repository layer speaks the category's engines.
- Each app ships with a planted "oops": a search path with no supporting
  index (for relational, orders searched by customer and status with only
  the primary key indexed). It is fast on a small table and slows as k6
  grows the data, so runbook 2 must find it from the dashboards and query
  statistics alone, and runbook 17 fixes it online (`CREATE INDEX
  CONCURRENTLY`; MySQL online DDL) without blocking writes. Other categories
  get their equivalent (an unindexed field in search, a full scan in
  Cassandra, a brute-force vector search before an index is built).
- Language: the most common match for the category's ecosystem, not a spread
  across languages. Datastores are network services now, not bundled into a
  C++ or Java monolith, so each service's language follows its client
  ecosystem. Java: relational, NoSQL (Cassandra), graph, streaming (Spring
  Boot; JVM-native drivers). Python: vector, object storage/analytics,
  search, in-memory, directory (AI/RAG and data-engineering clients,
  scripting). Go: time-series (the Prometheus/InfluxDB/Telegraf ecosystem).
- Load comes from Grafana k6 running a CRUDS mix against the app as a
  Kubernetes Job: create, read by key, **search**, update, delete, each
  weighted for the app (a web app is read-heavy, a meter app create-heavy)
  and measured separately. Search is kept apart from read because a key
  lookup costs about the same at any size, while a search (filter, rank,
  sort, aggregate, traverse, nearest-neighbour) depends on the query and the
  data: under a patch or failover, point reads often look fine while
  searches time out. Over HTTP: `GET` with a query string for simple
  filters, `POST .../_search` with a JSON body for complex ones (the
  OpenSearch convention; the body-carrying `QUERY` method is still an IETF
  draft). The job pushes results into
  Prometheus (remote write) with thresholds (p95 latency, error rate) as the
  SLO. Runbooks are judged by what this load sees. Engine-native benchmarks
  (pgbench, sysbench, memtier, YCSB) stay for the capacity runbook.

### What each category's example app does

| Category | Example app (realistic use) | CRUDS under k6 load |
|---|---|---|
| relational | Orders and customers | create/read/update/delete orders; list by customer |
| in-memory | Session store and cache in front of a slow lookup; rate limiter | set/get/expire sessions; cache hit ratio under load |
| search | Product catalogue search | index, search (full text, facets), update, delete documents |
| time-series | Meter/sensor readings: ingest, downsample, query by window | write points; range and aggregate queries; retention deletes |
| NoSQL | Event or activity feed per user (wide-column) | append, read latest N, update, delete by key |
| vector | Semantic search over document chunks (the retrieval half of RAG) | upsert embeddings, nearest-neighbour search, delete |
| graph | Fraud rings: accounts sharing devices, cards, addresses | create accounts and links; 2-3 hop traversals |
| object storage | Uploads: metadata in PostgreSQL, bytes in the object store via signed URLs | put, get, head, list, delete objects |
| directory | Users and groups for an identity provider | add, search/bind, modify, delete entries |

Object storage is mostly underneath an app (uploads, data lakes of
Parquet/Iceberg queried by Trino or ClickHouse, ML datasets and models,
backups, and the storage of disaggregated engines such as Milvus). Vector
databases serve semantic search, RAG, recommendations, duplicate/image
similarity and anomaly detection. Graph databases answer multi-hop
relationship questions (fraud, recommendations, permissions, IT topology,
knowledge graphs) that become chains of self-joins in SQL.

**Candidate cross-category app:** a document library. Upload a PDF (object
store), metadata in PostgreSQL, text chunks embedded on CPU into Milvus or
pgvector, semantic search over them. It shows "metadata in a database, bytes
in object storage" and the retrieval half of RAG together.

## 9. Platform decisions log

| Decision | Why |
|---|---|
| kind on Docker Desktop, 3 workers labelled `topology.kubernetes.io/zone` | Free; zone labels are what operators spread replicas across, as on EKS |
| `docker stop <node>` = zone outage | Closest local equivalent of losing a zone's power |
| kind local-path volumes | One volume per node, like local disk or EBS in one AZ |
| Own kubeconfig per cluster (`~/.kube/kind-<name>`), context always named | `~/.kube/config` and grid-meter's context are never touched |
| Local Terraform state per root | No S3 in the private cloud; a real one would use MinIO-like S3, Consul or `pg` |
| Two roots per category (operators, clusters); two for the platform (cluster, services) | Custom resources can't be planned before their CRDs exist; providers need the cluster's kubeconfig at plan time |
| CloudNativePG for PostgreSQL | Most active PostgreSQL operator; declarative major upgrades; quorum sync replication with `failoverQuorum` |
| Percona PXC operator for MySQL, not Oracle's MySQL Operator | Oracle's arm64 images are separate `-aarch64` tags the operator doesn't choose; Percona's are multi-arch |
| Backup store: Garage or SeaweedFS, not MinIO | MinIO community edition unmaintained, no images since October 2025 |
| CloudNativePG backups via the Barman Cloud plugin | The in-tree method is deprecated; the plugin requires cert-manager (a platform service) |
| Pins: kind provider 0.11.0, CNPG chart 0.29.1, PXC operator chart 1.20.1, kube-prometheus-stack 92.3.0 | Newest releases at least two weeks old |
| Passwords generated by operators/charts into Secrets | Never in Terraform state, never printed; scripts pass them on stdin |
| TLS required for every client, plaintext checked to be refused | Same bar as `rds.force_ssl` / `require_secure_transport` on Aurora |

### The laptop lab and its limits (decided 2026-10-26)

The lab is a MacBook Air: Apple M4, 10 cores (4 performance, 6 efficiency),
24 GB, fanless, one internal NVMe drive. All kind nodes share that drive
through the Docker Desktop VM's virtual disk, the same cores and one clock.

- 29 of the 39 runbooks test real behaviour; capacity, load baselines and
  tuning give only relative numbers (before/after on the same laptop, short
  runs repeated three times, never a capacity figure); six need workarounds
  (disk full, storage expansion, reformat, drain, DR, scale out); clock skew
  and disk health are simulated; write-cache cards, real filesystem tuning
  gains, NVMe isolation features, JBOD/RAID layouts and per-node disk
  isolation are documented practice only. Table: RUNBOOKS.md, "What the
  laptop lab can and can't test".
- Prerequisites: **at least 40 GB free on the Mac's disk** (on 2026-10-26 it
  had 13 GB free, 97% full: the first blocker); Docker Desktop at 12-14 GB
  memory and 8 CPUs (it was set to 4 CPUs); long tests under
  `caffeinate -i`; one category at a time; heavy engines in their smallest
  HA shape.
- Dedicated database nodes would isolate CPU and memory and show the
  pattern, but not disk I/O, because every node shares one disk; the
  noisy-neighbour drill demonstrates that limit openly.
- **Every kind node reports the whole VM as its own** (found 2026-10-26 in
  Grafana's nodes dashboard): four nodes x 8 CPUs and 13.6 GiB = 32 CPUs and
  54.5 GiB "allocatable" on an 8-CPU, 13.6 GiB VM. That is thin-provisioned
  compute, which the capacity rules forbid: the scheduler would place four
  times what fits, and a node never feels memory pressure until the whole VM
  does. So node isolation (dedicated nodes included) is not real until each
  node's allocatable is cut to its share, with kubelet `system-reserved` in
  the kind config (the kubelet then caps the node's pod cgroup at that
  size). Needs the cluster recreated, so it goes with the dedicated-nodes
  decision.
- Every add-on has a memory request and limit (Grafana reached 708 MiB as a
  BestEffort pod): the scheduler's arithmetic only works if nothing is
  unbounded.

## 10. Open questions

- Dedicated, tainted database nodes, two per zone (one in use, one spare,
  following the N+2 capacity rule; about 3 GB more memory), and a separate
  WAL volume for PostgreSQL: proposed, not yet decided; deferred to the
  node-drain and node-replacement runbooks. They isolate CPU and memory,
  not disk, and only once each node's allocatable is its real share (see
  the lab limits). Both need the cluster recreated: do them together.
- Whether cgroup v2 `io.max` works on the Docker Desktop VM's disk (for the
  noisy-neighbour containment step): to be tried.
- Distributed SQL engine: YugabyteDB or TiDB.
- Object store: Garage or SeaweedFS.
- ~~MySQL monitoring: exporter or PMM~~ Decided 2026-10-26: a
  `mysqld_exporter` sidecar into the shared Prometheus, so every category
  shares one monitoring stack and one alerting path; PMM would add a second
  server, its own agents and its own alerting for one engine.
