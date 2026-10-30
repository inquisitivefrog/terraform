# datastore-clusters: runbooks

Definitions of the day-2 work for every datastore in this tree: what each
runbook is for, when it is used, how it is done safely, and how success is
measured. Scripts implement them per category (`<category>/scripts/`); this
document is the specification they are written against. Design background:
[DESIGN.md](DESIGN.md).

Contents: [terms](#terms) - [template](#runbook-template) -
[capacity in a private cloud](#capacity-in-a-private-cloud) -
[storage practices](#storage-practices) - [lab limits](#what-the-laptop-lab-can-and-cant-test) - [the runbooks](#the-runbooks) -
[common problems](#common-problems-symptom-to-runbook)

## Terms

| Term | Meaning | Default target here |
|---|---|---|
| **RPO** (recovery point objective) | How much committed data may be lost | 0 for a single-zone failure (synchronous commit); minutes for a restore from backup (continuous WAL/binlog archiving) |
| **RTO** (recovery time objective) | How long until service is back | under 60 s for a node or zone failure; under 1 h for a restore |
| **SLO** (service level objective) | What users must see, measured by the k6 load | p95 latency and error rate per CRUDS operation, stated per app |
| **Headroom** | Capacity held back so failures and maintenance need no new hardware | see [capacity](#capacity-in-a-private-cloud) |
| **Blast radius** | What a change or failure can affect | one node, then one zone, never the cluster |

## Runbook template

Every runbook is written, scripted and judged the same way:

| Section | Contents |
|---|---|
| **Goal** | One sentence: the outcome |
| **When** | The triggers: a schedule, an alert, a symptom, a request |
| **Before** | Safety checks that must pass first: cluster healthy, a recent tested backup, headroom available, the change rehearsed on a clone where it is risky, someone watching dashboards |
| **Steps** | The procedure, smallest blast radius first (one replica, then the rest, the writer last) |
| **Verify** | `check_resources.sh` passes; replication caught up; the k6 SLO held |
| **Roll back** | How to undo it, and the point after which it can't be undone |
| **Measure** | What gets recorded: write outage (s), data lost (rows), time to heal, p95 during the change |
| **Engine notes** | What differs between engines |

Every runbook runs under the category's k6 CRUDS load. One that "worked"
while users saw errors has failed. Results are recorded in
`private/docs/STATUS.md`.

## Capacity in a private cloud

A public cloud lends capacity on demand: autoscaling borrows from the
provider's pool. A private cloud owns its pool, and new hardware takes weeks
or months to arrive. So headroom is bought in advance and runbooks assume it
is there.

| Resource | Over-subscription | Why |
|---|---|---|
| CPU | Acceptable (e.g. 2-4x across apps); avoid for databases | Too little CPU slows things down; it doesn't lose data |
| Memory | Not for databases (Guaranteed QoS: request = limit) | Over-committed memory ends in OOM kills: a database restart or crash recovery |
| Storage | **Never thin-provision beyond what can be backed** | A thin pool that fills up fails every volume on it at once, the worst storage incident there is |
| Nodes | N+2 per zone pool | One node out for maintenance and one failed still leaves full capacity |

Rules the capacity runbooks enforce:
- **Rebuild headroom.** Replacing a node re-copies its data from a peer: the
  cluster must have spare disk, network and IOPS for that copy while serving
  normal load.
- **Fork and compaction headroom.** Some engines temporarily need much more
  than their steady state: Valkey/Redis snapshotting forks (copy-on-write can
  approach 2x memory), Cassandra compaction can need up to 2x disk for a
  table, PostgreSQL `VACUUM FULL` and `pg_repack` rewrite the table.
- **Data per node is capped by rebuild time, not drive size.** Re-cloning a
  replaced member runs at roughly network speed (about 1 GB/s on 10 Gb), so
  10 TB per node is about 3 hours with one copy missing, 60 TB most of a day.
  Size nodes so a rebuild finishes well inside the window a second failure
  is unlikely in; prefer more, smaller nodes (faster rebuilds, smaller blast
  radius, parallel recovery in sharded engines). Media by tier: NVMe TLC for
  hot data, NVMe QLC for large read-mostly data, hard disks for backups and
  archives.
- **Zone loss.** Each zone's survivors must absorb the lost zone's load: with
  three zones, size each to run at no more than about 66% of what two zones
  can carry.
- **Thresholds.** Alert at 70% (plan), 80% (act), 90% (incident) for disk,
  memory and connections. Forecast growth, and order hardware when the
  forecast crosses 80% within the purchase lead time.

## Storage practices

The practices the runbooks check for, whatever the engine:

- **Redundancy by replication, not RAID alone.** Copies on separate nodes and
  zones survive what RAID can't (a controller, a node, a zone). With
  replicas, a node's disk can be a single NVMe or RAID 0; a dead disk is a
  dead node, replaced and re-cloned. RAID 10 remains the right choice for a
  single, unreplicated server.
- **Separate volumes for logs, data and (optionally) indexes and temp.**
  WAL/binlog/commit logs on their own volume: different write pattern, and a
  runaway log can't fill the data volume. Indexes and temporary files can
  get their own volumes too (PostgreSQL tablespaces, declared as separate
  volumes by CloudNativePG; InnoDB file-per-table with `DATA DIRECTORY`). On
  spindles this was about seek contention; on NVMe it is about isolating
  capacity and putting hot indexes on the fastest storage.
- **Filesystem, chosen and tuned at creation.** XFS or ext4. Several choices
  are fixed when the filesystem is made and can only be changed by
  reformatting: block size, inode count (ext4 `-i` bytes-per-inode for
  engines with many small files), XFS stripe unit and width matched to the
  RAID or volume geometry, reserved blocks (ext4 `-m`, 5% by default, often
  lowered on dedicated data volumes). In a replicated cluster a reformat is a
  rolling member replacement (runbook 20), not downtime. Mount with
  `noatime`; the `none` I/O scheduler for NVMe; no swap on database nodes (or
  `vm.swappiness` near 0); transparent huge pages off for Valkey/Redis and
  MongoDB. On Kubernetes these become StorageClass parameters (filesystem
  type, mkfs options where the CSI driver supports them).
- **Journaling.** Keep the filesystem's default metadata journaling (ext4
  `data=ordered`, XFS). Full data journaling (`data=journal`) writes
  everything twice for no gain: the database's own WAL/redo log already
  protects the data.
- **Honest fsync and the write cache.** A write cache must survive power
  loss: a battery-backed (BBU) or flash-backed RAID controller cache, or
  NVMe drives with power-loss protection (capacitors; enterprise drives have
  it, consumer drives usually don't). Otherwise disable the cache. A
  database is only as durable as the storage's answer to "is it on disk?".
  Watch the cache's state: a BBU's periodic learn cycle or a failing battery
  switches the controller to write-through, and write latency jumps until
  it ends.
- **The right SSD class, trimmed.** Enterprise TLC drives rated for mixed
  use (about 3 drive-writes-per-day) for databases; not consumer QLC, whose
  fast writes land in a small SLC cache and fall to hard-disk speed once it
  fills (a long load or a replica rebuild fills it). Over-provisioning and
  free space keep garbage collection from stalling writes; run TRIM with a
  periodic `fstrim` rather than the continuous `discard` mount option.
  Garbage collection still shows up as tail latency: watch p99, not
  averages.
- **Isolate I/O; capacity is easy to share, performance isn't.** One
  tenant's writes trigger the drive's garbage collection and stall every
  other tenant's reads. Kubernetes has no disk I/O requests or limits, so:
  give database members whole disks on dedicated nodes; keep write-heavy
  neighbours (log shippers, backups, compaction, batch jobs) off the
  database's disks; where sharing is unavoidable, cap the rest with cgroup v2
  `io.max`/`io.weight` or storage QoS (provisioned IOPS on cloud volumes,
  Ceph mClock, per-volume array QoS, `VolumeAttributesClass` where the
  driver supports it). Drive-level isolation (NVM Sets, Flexible Data
  Placement) exists but is not yet common outside the hyperscalers.
- **Disk health, not bad-block lists.** Drives remap bad sectors themselves
  now; the job is to watch SMART/NVMe health (reallocated and pending
  sectors, media errors, wear level) and replace a drive while it still
  works (runbook 4).
- **Watch inodes as well as bytes.** Engines with many small files (Elastic
  and OpenSearch segments, some time-series stores) can run out of inodes
  with space free.
- **Checksums on.** PostgreSQL data checksums (`initdb --data-checksums`, the
  default from version 18), InnoDB page checksums, so corruption is detected
  instead of replicated silently.
- **Encryption at rest**, with the key outside the data volume and rotation
  defined (see [key rotation](#39-encryption-key-rotation)).
- **Backups: 3-2-1, immutable, tested.** Three copies, two media, one off
  site; object-lock (write once) copies against ransomware and mistakes;
  and a backup only counts once a restore from it has worked.
- **Snapshots are not backups by default.** A storage snapshot (LVM, ZFS,
  SAN, CSI VolumeSnapshot) is crash-consistent at best. For a consistent
  copy, put the engine in backup mode first (PostgreSQL
  `pg_backup_start`/`pg_backup_stop`, which CloudNativePG does for volume
  snapshot backups; MySQL `LOCK INSTANCE FOR BACKUP`) or freeze the
  filesystem (`fsfreeze`), and keep a copy off the storage system that took
  the snapshot. Snapshots are excellent for fast clones and fast restores.
- **Expansion allowed.** StorageClasses with `allowVolumeExpansion`, so a
  filling volume can grow online.
- **Local volumes pin pods.** A pod on a local volume can't move: if its node
  dies, the operator must abandon that volume and re-clone elsewhere.

## What the laptop lab can and can't test

The lab is a MacBook Air (Apple M4: 10 cores, 4 performance + 6 efficiency;
24 GB; fanless) running Docker Desktop. Every kind node shares one physical
NVMe drive (through the VM's virtual disk), the same cores, and one clock;
there is no real hardware to fail. Results are read with that in mind.

| Testability | Runbooks |
|---|---|
| Real behaviour | 1, 2, 6, 7, 8, 9, 11-15, 17, 22-29, 31-34, 36-40 |
| Behaviour real, numbers only relative (before/after on the same laptop, short runs repeated 3x; never a capacity figure) | 3, 5, 16, and the noisy-neighbour drill in 2 |
| With a workaround | 30 disk full (kind volumes don't enforce size: a small fixed-size filesystem mounted into a node); 19 storage expansion (by replacing members, runbook 22); 20 reformat (inside a disk-image file); 21 drain (a Kubernetes version upgrade means recreating the cluster); 10 DR (a second, one-node kind cluster); 18 scale out (memory-bound) |
| Simulated | 35 clock skew (containers share the VM clock: per-process fake time only); 4 disk health (no SMART data: the alert pipeline is tested with synthetic metrics); I/O caps with cgroup `io.max` (if the VM's disk exposes the controller) |
| Not testable here | write-cache cards and battery learn cycles, real filesystem tuning gains, NVMe isolation features, multi-disk layouts (JBOD, RAID), per-node disk isolation: documented practice only |

Practical limits: one category at a time; Docker Desktop at 12-14 GB memory
and 8 CPUs; at least 40 GB free on the Mac's disk before the first apply
(images, volumes and the VM disk image grow); long tests under
`caffeinate -i` so the laptop doesn't sleep; heavy engines in their smallest
HA shape (Cassandra and OpenSearch with small heaps, Milvus in its smallest
cluster layout).

## The runbooks

40 runbooks in five groups (40 was added after the others, so it is numbered
last and listed next to 32, its server-side counterpart). **Bold** ones are the seven requested first; they
are built in this order: 1, 7, 13, 16, 22, 23, then 14 last. Each entry gives
goal, when, the key safety points and steps, how it is verified, and engine
notes. Implementation status lives in the README of each category.

### Observe

#### 1. **Monitor**
- **Goal:** know the health and performance of every cluster from metrics,
  logs and the user's view (k6) before anyone reports a problem.
- **When:** always on; dashboards reviewed during every other runbook.
- **Steps:** scrape the engine's metrics (PodMonitor/ServiceMonitor); ship
  dashboards as labelled ConfigMaps; define alerts (below); enable the query
  statistics view (`pg_stat_statements`, MySQL `performance_schema` and slow
  log).
- **Alerts every engine gets:** member down; quorum or primary lost;
  replication lag over threshold; disk, inodes, memory, connections over 80%;
  backup older than its schedule; certificate expiring within 14 days; error
  rate or p95 over SLO.
- **Verify:** each alert fired once on purpose (stop a replica, fill a
  volume) and cleared.
  Relational lab: rules in `modules/postgresql/cluster/alerts.tf`,
  `modules/mysql/cluster/alerts.tf` and `modules/orders-app/alerts.tf`
  (p95 per operation against the k6 SLO, error rate). `runbook_1_alerts.sh
  pg|mysql` fires member down (PostgreSQL: fence a replica; PXC: SIGSTOP a
  non-writer's mysqld from its node), lag (pause WAL replay; desync plus
  `FLUSH TABLES WITH READ LOCK`), connections over 80% (a pod of idle
  sessions) and the search SLO, and sees each reach Alertmanager and clear.
  Not fired: primary or quorum loss, memory, disk (local-path volumes
  report no usage; the stack's node filesystem rules cover the shared
  disk), certificates and backups (no metric, no backups yet).
  Alertmanager's receiver is still "null": nothing is sent anywhere.
  Results 2026-10-30: every tested alert fired in 91-152 s and cleared in
  31-91 s. `cnpg_collector_up` stays 1 for a fenced instance: count the
  instances that answer instead. A hung (frozen) Galera node stalled
  writes cluster-wide until it was evicted (12 failed creates); a
  cleanly stopped one does not.

#### 2. Find a performance problem
- **Goal:** go from "it's slow" to the cause: a query, a lock, a hot node, a
  resource limit.
- **When:** p95 over SLO; a slow-query alert; a user report.
- **Steps:** the USE method on each node (utilisation, saturation, errors for
  CPU, memory, disk, network), then the top queries by total time, then
  waits and locks, then the plan (`EXPLAIN (ANALYZE, BUFFERS)`). Fix the
  cause (index, query, statistics, pooling), not the symptom (bigger
  hardware).
- **Verify:** the app's planted slow search (a missing index) is found from
  the dashboards and query statistics alone, fixed online (runbook 17:
  `CREATE INDEX CONCURRENTLY`, MySQL `ALGORITHM=INPLACE, LOCK=NONE`) with no
  failed writes, and p95 returns under SLO. One change at a time, measured
  before and after.
- **Second planted problem: a noisy neighbour.** A disk benchmark (`fio`
  random writes) runs on one node's volume; every kind node's volumes share
  the Docker Desktop VM's disk, so the databases' p99 rises on all nodes.
  The runbook must trace it from per-volume and per-cgroup I/O metrics to the
  offending pod, then contain it (stop, cap with `io.max`, or move it).

#### 3. Capacity planning and headroom
- **Goal:** know the limit of each cluster and when it will be reached, in
  time to buy hardware.
- **When:** monthly; after every load-profile change.
- **Steps:** baseline throughput per node with the engine's own benchmark
  (pgbench, sysbench, memtier, YCSB, opensearch-benchmark); record growth of
  data, connections and request rate; forecast; compare with the headroom
  rules above.
- **Verify:** a report per cluster: current use, limit, months until 80%.

#### 4. Disk and hardware health
- **Goal:** replace failing disks, controllers and hosts before they fail,
  from their own health data.
- **When:** continuous; alerts on any change in the counters below.
- **Steps:** collect SMART/NVMe health (smartctl exporter or the node
  exporter's hardware collectors): reallocated and pending sectors, media
  and CRC errors, wear (percentage used), temperature; RAID controller and
  cache battery state; kernel I/O errors (`dmesg`). On a warning, treat the
  member as damaged (runbook 22) and replace the drive.
- **Engine notes:** a disk returning bad data is caught by checksums
  (runbook 31); a disk that is merely slow shows as one member's high I/O
  latency and, in Galera, as flow control.

#### 5. Load test (baseline and before/after)
- **Goal:** a repeatable CRUDS load and a recorded baseline, so any change can
  be compared.
- **When:** before and after every Change runbook; after upgrades.
- **Steps:** run the category's k6 test at fixed rates; store results in
  Prometheus; compare p50/p95/p99 and errors per operation.
  Relational lab: `load_test.sh pg|mysql run [rate] [duration]`, logged as
  runbook 5.

#### 6. Audit trail review
- **Goal:** know who connected and what privileged actions they took.
- **When:** monthly; after an incident.
- **Steps:** enable connection and DDL/privilege logging (pgAudit, MySQL audit
  log); ship logs off the cluster; review new users, grants, failed logins.

### Protect

#### 7. **Back up**
- **Goal:** recoverable copies of every cluster, off the cluster, on a
  schedule, with continuous log archiving where the engine supports it.
- **When:** scheduled (full daily, logs continuously); on demand before any
  Change runbook.
- **Before:** object store reachable; retention defined; encryption on.
- **Steps:** configure the operator's backup to the object store (Barman Cloud
  plugin for CloudNativePG; XtraBackup for PXC; snapshots for OpenSearch;
  Medusa for Cassandra; RDB/AOF copies for Valkey); take backups from a
  replica where supported, never loading the writer; set retention; make
  one copy immutable (object lock).
- **Verify:** the backup alert ("last good backup older than schedule")
  stays quiet; every backup is restore-tested (8).
- **Engine notes:** caches may need no backup at all (state the decision).

#### 8. Restore (into a new cluster)
- **Goal:** a working cluster from a backup, proving the backup is real.
- **When:** weekly automated test; on data loss.
- **Steps:** restore into a fourth, temporary cluster (never over the live
  one); run consistency checks and row counts against expectations; record
  restore time (the realistic RTO); delete the temporary cluster.
- **Verify:** application queries succeed against the restored cluster.

#### 9. Point-in-time recovery
- **Goal:** recover to just before a mistake (a bad `DELETE`, a broken
  migration).
- **When:** human or application error.
- **Steps:** find the time or transaction of the mistake (logs, audit); restore
  the base backup and replay WAL/binlog to just before it into a new
  cluster; copy the lost rows back, or cut over to the recovered cluster.
- **Verify:** the deleted rows are back; nothing after the recovery point is
  silently lost (reconcile or accept explicitly).

#### 10. Disaster recovery to a second site
- **Goal:** survive losing the whole data center.
- **When:** DR test twice a year; real site loss.
- **Steps:** a replica cluster at a second "site" (another kind cluster,
  standing in for another data center) fed by streaming replication or from
  the backup store; promote it; repoint clients; later rebuild the original
  as the replica and fail back.
- **Measure:** data lost (asynchronous across sites: RPO above zero) and time
  to promote.

#### 11. Data retention and purge
- **Goal:** delete data on schedule (retention policy, right to erasure)
  without hurting the cluster.
- **Steps:** partition by time and drop old partitions instead of mass
  `DELETE`; TTLs for caches, Cassandra, time-series; batched deletes with
  pauses when unavoidable; then reclaim space (vacuum, compaction).
- **Engine notes:** Cassandra tombstones from deletes slow reads until
  compaction and must be repaired within `gc_grace_seconds`; PostgreSQL
  mass deletes cause bloat.

#### 12. Backup and archive storage check
- **Goal:** the backup store itself is healthy, has space and keeps what
  retention promises.
- **When:** weekly.
- **Steps:** check free space and growth of the object store, object-lock
  settings, that expired backups are actually pruned, and that archived
  WAL/binlogs are continuous (no gaps).

### Change

#### 13. **Security patch (minor version)**
- **Goal:** move to the latest minor release within days of its release,
  without downtime.
- **When:** a security release; monthly otherwise.
- **Before:** release notes read; backup fresh; patch running on a clone
  first.
- **Steps:** replicas one at a time, each back in sync before the next; then
  a planned switchover so the old writer becomes a replica; patch it.
- **Verify:** every member on the new version; k6 errors only during the
  switchover (seconds).
- **Engine notes:** CloudNativePG does replicas then switchover when the image
  changes (`primaryUpdateStrategy`); PXC's SmartUpdate restarts nodes one at a
  time, the writer last.
  Relational lab: `runbook_13_patch.sh pg|mysql` watches a Terraform apply
  of the new image under k6 load. CloudNativePG's `primaryUpdateMethod`
  defaults to `restart` (the primary restarts in place, no writer
  meanwhile); the lab sets `switchover`. 2026-10-30: PostgreSQL 16.13 ->
  16.15 in 188 s (replicas, switchover, old primary), ~5 s of app errors
  (3 of 17,922 requests); PXC 8.0.44 -> 8.0.46 in 347 s (writer last; writes
  moved away and back), ~20 s of app errors (65 of 17,880); 0 acknowledged
  writes lost on both. MySQL 8.0 cannot go back a minor.

#### 14. **Major version upgrade**
- **Goal:** move to a newer major release before the old one ends support,
  with a tested way back.
- **When:** at least a year before end of life; never in a hurry.
- **Before:** compatibility review (removed features, changed defaults,
  extensions, client drivers); a full rehearsal on a restored copy with the
  app's tests and replayed queries; a fresh backup; a rollback decision
  point agreed.
- **Steps (choose one):** in place (PostgreSQL `pg_upgrade` via CloudNativePG;
  offline); or blue/green: a new cluster on the new version, fed by logical
  or asynchronous replication, cut over, old cluster kept for fallback
  (Percona's recommended path for PXC 8.0 to 8.4).
- **Verify:** statistics refreshed (`ANALYZE`); query plans and p95 compared
  with the baseline (5).
- **Roll back:** in place, only by restore; blue/green, by repointing back
  until the old cluster is discarded.

#### 15. Operator upgrade
- **Goal:** upgrade the control plane (CloudNativePG, Percona operator)
  separately from the databases.
- **Steps:** read the upgrade notes (CRD changes, supported database
  versions); upgrade CRDs, then the operator; watch that it adopts the
  existing clusters without restarting them unexpectedly.
- **Engine notes:** some operator upgrades roll every database pod (new
  sidecar or instance manager): treat that as a rolling restart and plan it.

#### 16. **Tune configuration**
- **Goal:** change settings safely and prove the effect.
- **When:** a performance finding (2); a capacity change (resized nodes).
- **Before:** know whether the setting reloads or needs a restart.
- **Steps:** change in Terraform; let the operator apply it (reload, or a
  rolling restart with switchover); compare k6 and benchmark results before
  and after.
- **Engine notes:** PostgreSQL `shared_buffers`, `max_connections` restart,
  `work_mem` reloads; MySQL `innodb_buffer_pool_size` is resizable online,
  many others aren't; Galera `wsrep_provider_options` and `gcache.size`.

#### 17. Schema and data migration
- **Goal:** change the schema with no failed writes.
- **Steps:** expand (add, nullable or defaulted), deploy code that writes
  both, backfill in batches, switch reads, contract (drop the old) in a
  later release.
- **Engine notes:** PostgreSQL DDL is transactional but takes locks: set
  `lock_timeout`; MySQL 8 `ALGORITHM=INSTANT` for many column adds, else
  gh-ost or pt-online-schema-change; Galera DDL replicates in total order and
  blocks the cluster: use online tools or rolling schema upgrade (RSU).
  Relational lab: `runbook_17_index.sh` adds the planted missing index
  under load. PostgreSQL, 2026-10-27, 3 million orders: `CREATE INDEX
  CONCURRENTLY` in 2 s at 20 requests/s, 0 of 1,720 writes failed; searches
  went from parallel table scans (151 ms) to backward index scans (0.5 ms),
  and 150 requests/s, failing before, met every SLO (search p95 2 ms).
  PXC, 2026-10-28: pt-online-schema-change (`--chunk-time 0.1`) copied 3
  million rows in 1.6 min, 0 of 6,287 writes failed; with the default
  0.5 s chunks one create had failed (row locks on the copied chunk held
  writer connections). Online means no failed writes, not no slowdown:
  during the copy write p95 rose from ~3 to 15-20 ms, max 1.8 s. Plain
  ALTER would stall the cluster (Galera TOI).
  150 requests/s then met every SLO (search p95 2.6 ms). The node memory
  must allow a full buffer pool: the copy fills it on every node, and at
  1536Mi the writer was OOM-killed (runbook 34). The lab script drops the
  index again at the end, so the runbook can be repeated.

#### 18. Scale out and in
- **Goal:** add or remove members without disrupting clients.
- **Steps:** add a member and wait until it is in sync before giving it
  traffic; remove members by draining them from routing first; for sharded
  engines (Cassandra, OpenSearch, Valkey Cluster) rebalance data and watch
  the rebalance traffic.
- **Engine notes:** keep quorum sizes odd (3, 6); scaling in a quorum
  system lowers how many failures it survives.

#### 19. Storage expansion
- **Goal:** grow a filling volume before it is full, online.
- **When:** the 80% disk alert; a forecast.
- **Steps:** raise the size in Terraform; the operator expands each PVC
  (StorageClass must allow it); confirm the filesystem grew.
- **Engine notes:** kind's local-path storage can't expand: the runbook
  instead replaces members with bigger volumes one at a time (22), which is
  also how fixed local disks are handled on real hardware.

#### 20. Storage migration and reformat
- **Goal:** move a cluster to a different storage class (faster disks, a new
  array) without downtime.
- **Steps:** replace members one at a time with ones on the new storage
  (22), or blue/green via a replica cluster.

#### 21. Kubernetes node drain and platform upgrade
- **Goal:** maintain or upgrade nodes while the databases stay up.
- **Steps:** drain one node at a time; PodDisruptionBudgets stop a drain that
  would break quorum; operators switch the primary away first.
- **Verify:** drain respects the budgets; k6 sees at most a switchover.
- **Engine notes:** a pod on a local volume can't move: its node's drain
  waits for the node to return, or the member is rebuilt elsewhere.

### Recover

#### 22. **Replace a damaged node**
- **Goal:** take a member with a bad disk or host out and bring a fresh one
  in, with no data loss and no outage.
- **When:** disk errors, checksum failures, a dead host, a member that won't
  rejoin.
- **Steps:** fence the member (stop it); delete its volume and pod; the
  operator creates a new member that copies data from a healthy peer
  (`pg_basebackup` for CloudNativePG; SST for Galera; bootstrap and repair for
  Cassandra; shard recovery for OpenSearch).
- **Before:** headroom for the copy (disk, network); the copy source is not
  the writer where avoidable.
- **Measure:** time to re-clone per GB; p95 during the copy.

#### 23. **Planned switchover and forced election**
- **Goal:** move the writer deliberately (planned), or recover when the
  cluster can't elect one itself (forced).
- **Planned:** CloudNativePG switchover to a named replica; PXC/HAProxy moves
  the writer; Valkey `CLUSTER FAILOVER`; OpenSearch excludes a node from
  voting.
- **Forced:** after losing quorum. Galera: on the most advanced survivor
  (highest `seqno`), set `pc.bootstrap=YES`; PostgreSQL: promote a replica
  manually only after making sure the old primary is truly down (fencing).
  Accept and record the data that only the lost members had.
- **Verify:** exactly one writer; clients reconnected; no split brain (28).
  Relational lab: `runbook_23_switchover.sh pg|mysql` does the planned
  switchover and back under k6 load. PXC has no switchover command:
  `pxc_maint_mode=MAINTENANCE` fails the node's HAProxy health check
  (`haproxy_check_pxc.sh` requires `DISABLED`), so writes move while the
  node stays in the cluster.

#### 24. Writer failure (unplanned election)
- **Goal:** when the writer dies, a new writer is elected automatically with
  no committed data lost, and clients follow it.
- **Steps (test):** kill the writer's pod (crash) or stop its node (host
  loss) under k6 load (`failover_test.sh <engine> pod|zone`).
  Relational lab: `runbook_24_writer.sh pg|mysql` does the pod case under
  k6 load and judges RPO 0, outage within the RTO, and the app's writes
  succeeding after recovery. PostgreSQL waits `failoverDelay` (5 s here)
  before promoting, so a primary whose pod restarts sooner keeps its role.
  Results 2026-10-29, 20 requests/s: PostgreSQL ~17 s write outage for new
  connections (5 s failoverDelay, then the 15 s smart shutdown), 0 app
  writes failed, 0 lost; with failoverDelay 30 it was ~33 s and 53 app
  writes failed. Zone loss (`failover_test.sh pg zone`): ~61 s, of which 48
  s is Kubernetes noticing the lost node; PXC zone ~43 s (HAProxy's health
  check).
  The first run took 184 s: a deleted primary does a smart shutdown,
  refusing new connections while open ones keep working, for up to
  `smartShutdownTimeout` (default 180 s), and failover waits for it. Pooled
  clients never disconnect, so it waits the full time: set it low (15 s
  here). PXC: HAProxy moved writes in 2 s; 0 failed writes, 0 lost.
- **Expected:** detection, election and repointing of the writer endpoint
  within the RTO; RPO 0 with synchronous or quorum commit; the old writer
  returns as a replica (CloudNativePG rewinds it with `pg_rewind`; a Galera
  node rejoins by IST or SST).
- **Measure:** time to detect, to elect, until k6 writes succeed again;
  failed writes; rows lost (must be 0).

#### 25. Reader failure
- **Goal:** losing a replica costs read capacity only: no write outage, no
  data loss.
- **Steps (test):** kill one replica's pod, then its node, under k6 load;
  then two replicas.
- **Expected:** the reader endpoint drops the failed member within seconds
  and reads move to the others; writes continue. Exceptions to verify:
  PostgreSQL with quorum commit (ANY 1 of 2) keeps writing with one replica
  down, but stops writes when both are down (`dataDurability: required`, by
  design); Galera treats every node as a voting member, so two of three down
  is a quorum loss (runbook 27).
- **Measure:** read errors and p95 during the failure; time until the
  replica is back and caught up.
  Relational lab: `runbook_25_reader.sh pg|mysql` covers the pod case (one
  replica) under k6 load; the node and two-replica cases are not scripted.

#### 26. Zone outage
- **Goal:** survive losing one zone with no data loss.
- **Steps (test):** `docker stop` every node in a zone; measure failover and
  the k6 view; restart; measure the rejoin and catch-up.
- **Expected:** writes resume within the RTO; RPO 0.
  Relational lab: `runbook_26_zone.sh pg|mysql` stops the writer's zone
  under k6 load (k6 outside the zone) through `failover_test.sh … zone`
  and judges the RTO, RPO and recovery. Probe-only results 2026-10-29:
  PostgreSQL ~61-64 s (48 s of it Kubernetes noticing the lost node),
  PXC ~43-50 s. First runbook run (PXC, 2026-10-30): database ~42 s, but
  the app ~77 s: the dead zone's app pod stays in the Service until the
  node is NotReady (50 s by default). The lab now sets
  node-monitor-grace-period to 20 s, and the runbook judges the app's
  outage (k6) as well as the database's.
  With 20 s (2026-10-30): PXC database ~14-22 s; PostgreSQL ~28 s, but
  one run had no failover for ~314 s: CloudNativePG's operator, not the
  instances, decides a failover, and its only copy was in the lost zone
  (evicted after the default 300 s). Both operators now run 2 copies, one
  per zone; with the leading copy killed alongside the primary, the
  standby took over at once and the failover took 30 s (database ~35 s).
  k6's 30 s connect wait on a pod in the lost zone inflated the app's
  outage to ~60 s; requests now time out at 15 s (above the app's ~13 s
  retry budget). Passes: PXC app ~10 s, PostgreSQL app ~25 s.

#### 27. Quorum loss
- **Goal:** know what happens when a majority is lost, and recover safely.
- **Steps (test):** stop two of three zones. Expected: writes stop (no
  quorum, by design); reads may continue on the survivor depending on the
  engine. Recover by restarting the zones; only if they are gone, force
  (23).

#### 28. Split brain
- **Goal:** never have two writers; detect and resolve it if it happens.
- **Prevention:** odd member counts, quorum-based promotion, fencing of the
  old writer, Kubernetes Services pointing at one writer only.
- **Steps:** detect (two members claim the writer role, or diverging
  data); stop one side immediately; choose the survivor by most recent
  durable commit; rebuild the other side (22); reconcile writes made on the
  losing side.

#### 29. Replication lag or a broken replica
- **Goal:** a replica that falls behind or stops replicating is caught up or
  rebuilt.
- **Steps:** find the cause (long queries on the replica, I/O saturation,
  network, a large transaction); fix or rebuild (22).
- **Engine notes:** PostgreSQL inactive replication slots retain WAL until
  the disk fills: cap with `max_slot_wal_keep_size` and alert; Galera flow
  control pauses the whole cluster for one slow node
  (`wsrep_flow_control_paused`).
  PostgreSQL replicas serving long reads: with `hot_standby_feedback` off,
  vacuum on the primary removes rows a replica query still reads; replay
  waits up to `max_standby_streaming_delay` (30 s), then cancels the query
  (40001) or terminates the connection (an EOF to the client). Seen
  2026-10-27 at 150 requests/s: lag up to 22 s, 1,102 snapshot conflicts
  (`pg_stat_database_conflicts`). Fix: `hot_standby_feedback = on`, a
  reload, not a restart. Verified the same day, same load: no new
  conflicts, lag 0 s, 0.35% dead rows kept on the primary.

#### 30. Disk full
- **Goal:** recover a member whose volume filled, and stop it recurring.
- **Steps:** find what grew (data, WAL/binlog, logs, temp files); free space
  safely (never delete WAL by hand): drop a stuck replication slot, expire
  binlogs, rotate logs; grow storage (19); add the missing alert.
- **Engine notes:** OpenSearch flood-stage watermark (95%) makes indices
  read-only until cleared; PostgreSQL stops accepting writes when WAL can't
  be written.

#### 31. Corruption detected
- **Goal:** contain corruption to one member and restore good data.
- **Steps:** confirm with checksums or the engine's checks (`amcheck`,
  `CHECK TABLE`); stop reads from the bad member; rebuild it from a healthy
  peer (22); if every copy is bad, restore (8, 9).

#### 32. Connection exhaustion (server side)
- **Goal:** recover when clients use up all of the database's connections
  (`max_connections`), and prevent it. The client-side counterpart, an
  application's own pool full while the database has slots to spare, is 40.
- **Steps:** find the clients (by application, user, host); kill idle ones;
  add or fix pooling (PgBouncer, ProxySQL, client pool sizes); set per-user
  limits.

#### 40. Connection pool saturation (client side)
- **Goal:** an application whose connection pool is full sheds load quickly
  and recovers, instead of queueing and retrying until every request times
  out; and the cause (usually slow queries, not a small pool) is fixed.
- **When:** pool `pending` above 0 for more than a few seconds; connection
  acquire time rising; errors like "Connection is not available, request
  timed out" (HikariCP) while the database still has connections to spare.
- **Why it differs from 32:** the database looks healthy by its own
  connection count; the queue is inside the application. Little's law sets
  the pool's need: connections busy = request rate x query time. When a
  query goes from 10 ms to 1 s, the same traffic needs 100 times the
  connections; a bigger pool then only runs more slow queries at once on an
  already saturated node.
- **Steps:** confirm from the app's pool metrics (active = max, pending
  rising) and the database's (connections well under `max_connections`,
  queries slow); find the slow statement (2); shed load: fail fast with 503
  on acquire timeout and **never retry a full pool** (retries are for a
  failed connection, not a busy one); keep acquire timeouts shorter than the
  client's own timeout; isolate workloads in separate pools (bulkheads:
  searches can't starve writes); fix the query (17), then resize the pool
  from Little's law with headroom.
- **Verify:** under the same k6 load, pending returns to 0, acquire time to
  milliseconds, and the operation's SLO holds; no retries on acquire
  timeouts.
- **Engine notes:** found 2026-10-27 on PXC at 3 million orders: the
  planted unindexed search held all 10 reader connections per pod, 45
  requests waited per pod, and the app retried each acquire timeout up to 4
  times (2,924 retries in 5 minutes, searches up to 17 s). Fixed in the app
  (orders 0.1.1): a pool timeout with no underlying connection failure is
  not retried.
  PostgreSQL at 150 requests/s showed the second half: Spring calls a
  statement timeout (`57014`) transient, so 573 timed-out 5 s scans ran
  again (searches up to 12.3 s). Orders 0.1.2 retries neither a full pool
  nor a statement timeout. Full Verify passed after runbook 17 on
  PostgreSQL (2026-10-27): at 150 requests/s, 0 connections waiting in
  either pool and every SLO met.

#### 33. Runaway query, lock pile-up or long transaction
- **Goal:** stop a query or transaction that blocks others or exhausts
  resources.
- **Steps:** find the blocker (`pg_stat_activity` with `pg_blocking_pids`,
  `performance_schema.data_lock_waits`); cancel, then terminate if needed; set
  statement and idle-in-transaction timeouts.
- **Engine notes:** PostgreSQL long transactions block vacuum (bloat, and in
  the extreme transaction ID wraparound, which forces a shutdown); Galera
  large transactions stall replication (`wsrep_max_ws_size`).

#### 34. Out of memory (OOM kill)
- **Goal:** a member killed for memory restarts cleanly, and the cause is
  fixed.
- **Steps:** confirm (container status `OOMKilled`); find what grew (work
  memory per query times connections, caches, fork for snapshots); set limits
  the engine respects (PostgreSQL memory settings, Valkey `maxmemory` and
  eviction policy, JVM heap at half the container memory for
  OpenSearch/Cassandra).

#### 35. Clock skew
- **Goal:** clocks on all nodes stay in sync.
- **Why:** Cassandra resolves conflicts by timestamp (last write wins); TLS
  and tokens check times; logs become impossible to correlate.
- **Steps:** NTP/chrony on every host; alert on offset; fix before trusting
  any timestamp-based data.

### Secure

#### 36. Credential rotation
- **Goal:** change database passwords and keys without downtime.
- **Steps:** create the new credential alongside the old; roll clients to it;
  revoke the old one. Operators rotate their own system users when the
  Secret changes.

#### 37. Certificate rotation
- **Goal:** renew TLS certificates before they expire, without dropping
  connections.
- **When:** the 14-day expiry alert; on CA compromise.
- **Steps:** let the operator or cert-manager renew; confirm members reload
  the new certificate; clients trust the CA, not the leaf.

#### 38. Access review
- **Goal:** only the people and services that need access have it, with the
  least privilege.
- **When:** quarterly; when someone leaves.
- **Steps:** list users, roles, grants and network policies; remove unused
  ones; check that applications don't use superuser accounts.

#### 39. Encryption key rotation
- **Goal:** rotate the keys protecting data at rest and backups.
- **Steps:** rotate the key-encryption key in the key manager; re-wrap data
  keys; confirm that old backups stay readable for their retention period.

## How each engine elects a writer

Runbooks 23-28 depend on this. "Quorum" means a strict majority of voting
members.

| Engine | Who decides | Writer failure | Reader / member failure |
|---|---|---|---|
| PostgreSQL (CloudNativePG) | The operator, using the Kubernetes API as its source of truth; no consensus among the databases themselves | Promotes the replica known to hold every acknowledged commit (`failoverQuorum`); old primary rejoins via `pg_rewind` | No election; reader endpoint drops it; quorum commit needs 1 of the remaining replicas |
| MySQL (Galera / PXC) | Every node votes; the side with a majority stays the Primary Component | No leader to elect: HAProxy sends writes to another healthy node | Any node down: fine while a majority remains; a minority stops serving |
| Raft engines (etcd, YugabyteDB, TiDB, Kafka KRaft, OpenSearch cluster manager) | Members elect a leader by majority vote, per group or shard | New leader within seconds (election timeout) | Fine while a majority of each group remains |
| MongoDB replica set | Members vote (Raft-like) | A secondary is elected primary (about 10 s) | Fine while a majority remains |
| Valkey / Redis | Sentinel quorum, or a majority of primaries in Cluster mode | A replica of the failed primary is promoted | Replica loss: reads move; primary loss: as left |
| Cassandra | Nobody: leaderless; every replica takes writes | No election: requests go to other replicas; consistency level (e.g. `QUORUM`) decides success | Same: hinted handoff and repair catch the member up |

## Common problems: symptom to runbook

| Symptom | Common causes | Runbooks |
|---|---|---|
| Writes failing, reads fine | Writer lost; quorum lost; disk full on the writer; synchronous standby missing | 23, 27, 30 |
| One search slows as data grows | Missing index (the app's planted "oops") | 2, 17 |
| One cluster slow, its own metrics normal, disk latency high | A noisy neighbour on the same disks (another workload, a backup, compaction) | 2, 4 |
| Everything slow | Hot query or missing index; lock pile-up; I/O saturation; noisy neighbour; Galera flow control | 2, 33, 29 |
| Slow after an upgrade | Statistics missing; plan regression; changed defaults | 14 (ANALYZE, compare plans), 2 |
| Disk filling fast | Inactive replication slot; binlog retention; logs; bloat from long transactions; tombstones | 29, 30, 33, 11 |
| Replica far behind | Long query on the replica; big transaction; slow disk or network | 29 |
| A member won't rejoin | Diverged data; corrupted volume; missing WAL or gcache | 22, 31 |
| "Too many connections" | No pooling; connection leak; retry storm after a failover | 32 |
| "Connection is not available, request timed out" in the app; database connections normal | Slow queries holding the pool; retries feeding the queue; pool shared by fast and slow work | 40, 2 |
| Write latency spikes every few weeks, then normal | RAID controller cache in write-through: battery learn cycle or failing battery | 4 |
| Members restarting | OOM kill; failing liveness probe under load; crash on corruption | 34, 31 |
| Two writers | Network partition with a promotion that wasn't fenced | 28 |
| TLS errors suddenly | Certificate expired; clock skew | 37, 35 |
| Backup "succeeded" but restore fails | Untested backups; WAL gaps; wrong encryption key | 8, 12, 39 |
| Cache stampede after a restart | Every client misses the cold cache at once | 34; app-side request coalescing and jittered TTLs |
| Search cluster read-only | OpenSearch/Elasticsearch flood-stage disk watermark | 30 |
| Deleted data reappears (Cassandra) | Repair not run within `gc_grace_seconds` | 11, 18 |
