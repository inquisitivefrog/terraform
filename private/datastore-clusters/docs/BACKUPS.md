# Backups

How the relational clusters are backed up, what each new piece is, and how
to look at it. Written while building it (2026-10-30): the parts marked
**to confirm** are what the documentation says and will be checked by the
first backup and restore (runbooks 7, 8 and 9 in [RUNBOOKS.md](RUNBOOKS.md)).

## The idea

A backup is a copy kept **somewhere else**, from a known point in time.
Replicas don't replace it: they copy a bad `DELETE` to every node within
milliseconds. A journal (the filesystem's, or the database's own WAL / redo
log) doesn't either: it makes a crash recoverable, on the same disk.

Modern practice, used here for both engines:

| Piece | How often | Gives |
|---|---|---|
| Transaction log archiving (PostgreSQL WAL, MySQL binlogs) | continuously, seconds to a minute | RPO: how much can be lost |
| Full (base) backup | on a schedule (here weekly; runbooks take more on demand) | the starting point of every restore; more recent means less log to replay (RTO) |
| Point-in-time recovery (PITR) | at restore | the newest full backup before the target time, plus the logs replayed up to it: "just before the bad DELETE" |

Full backups are physical (copies of the data files, taken while the
database serves), not logical dumps (`pg_dump`, `mysqldump`): much faster to
restore, and the only kind that PITR builds on. A logical dump still has a
place, for example to move data across major versions (runbook 14).

## The pieces

```
 laptop (Docker Desktop)
 ├─ container datastore-backups ─ SeaweedFS, S3 on 127.0.0.1:8333
 │    volume datastore-backups-data      buckets pg-backups, mysql-backups
 │    keys: ~/.config/datastore-dev/backup-store/s3.json (mounted read-only)
 │                ▲ S3 over http://host.docker.internal:8333
 └─ kind cluster datastore-dev           │
      cert-manager ── certificates ──► plugin-barman-cloud (cnpg-system)
      CloudNativePG operator ── mTLS ──►      │ adds a sidecar to each pg pod
      relational namespace:                   ▼
        pg-1..3   postgres + plugin-barman-cloud sidecar ── WAL, base backups ──┘
        mysql-pxc-0..2 ── backup Job (on demand / weekly) ────── full backups ──┘
        mysql-pitr (binlog collector) ─────── binlogs each minute ──────────────┘
        Secrets pg-backup-s3, mysql-backup-s3 (each engine's key)
```

### The store: SeaweedFS (`platform/environments/dev/backup-store`)

- **What:** an open-source object store with an S3-compatible API (Apache
  2.0 licence, maintained since about 2015). `weed mini` runs all its parts
  in one process, for one machine. MinIO, the usual choice until 2025,
  stopped shipping its community edition.
- **Why outside the cluster:** the cluster is destroyed and rebuilt often.
  The store plays S3 in another account: backups outlive the cluster, so a
  restore into a brand-new cluster (runbooks 8 and 10) is real.
- **Reached at:** `http://localhost:8333` from the laptop and
  `http://host.docker.internal:8333` from pods (Docker Desktop's name for
  the laptop; pods can't resolve container names). Published on 127.0.0.1
  only: nothing off the laptop can reach it.
- **On a cloud:** S3, Cloud Storage or Blob Storage instead, with no store to
  run; only the endpoint and the keys change.

### The keys

- `platform/scripts/backup_store_keys.sh` writes one S3 identity per engine
  to `~/.config/datastore-dev/backup-store/s3.json` (mode 600), each allowed
  only its own bucket: a leaked PostgreSQL key can't read or delete the
  MySQL backups. No anonymous access.
- The store mounts that file read-only. Terraform holds only its path: no
  key is ever in Terraform state (the repo rule for passwords).
- `relational/scripts/backup_secrets.sh` copies each engine's key into a
  Kubernetes Secret in `relational` (`pg-backup-s3`, `mysql-backup-s3`),
  through kubectl's stdin. Rerun it after `backup_store_keys.sh --rotate`.

### cert-manager (`platform/environments/dev/services`)

- **What:** the standard Kubernetes tool for issuing and renewing TLS
  certificates, from `Issuer` and `Certificate` resources. Three small
  Deployments: the controller, a webhook that validates its resources, and
  the cainjector that writes CA bundles where Kubernetes needs them.
- **Why here:** the Barman Cloud plugin and the CloudNativePG operator talk
  over mutual TLS (each side proves itself with a certificate); the
  plugin's chart asks cert-manager for both. The databases keep their own
  operator-made certificates.
- Its CRDs stay if the chart is removed: deleting them would delete every
  certificate in the cluster.

### PostgreSQL: the Barman Cloud plugin

- **Barman** is EDB's long-standing PostgreSQL backup tool;
  **barman-cloud** is its set of commands that write straight to object
  storage. CloudNativePG used to run them itself (`barmanObjectStore` in the
  Cluster); that built-in support is deprecated and due for removal, and
  this plugin replaces it (CNPG-I, CloudNativePG's plugin interface).
- **Two parts:**
  - the `plugin-barman-cloud` Deployment in `cnpg-system` (it must share the
    operator's namespace): when the operator creates an instance pod, it asks
    the plugin, which adds a sidecar;
  - the `plugin-barman-cloud` sidecar in every instance pod: it ships WAL and
    takes base backups with barman-cloud.
- **Resources** (`relational/modules/postgresql/cluster/backup.tf`):
  - `ObjectStore` `pg-backups`: bucket, endpoint, key Secret, compression
    (base backups bzip2, the smallest; WAL zstd), retention (a recovery
    window of 7 days: everything needed to restore to any moment in the
    last 7 days is kept, older backups are deleted after the next one);
  - the Cluster's `plugins` entry: the sidecar, and `isWALArchiver: true`;
  - `ScheduledBackup` `pg-scheduled`: a base backup each Sunday 03:00 UTC
    (CloudNativePG's cron has seconds first: `0 0 3 * * 0`), from a replica
    when one is healthy (`prefer-standby`);
  - `Backup`: one backup, made by a runbook or by hand.
- **WAL archiving:** PostgreSQL hands each finished 16 MB WAL segment to
  the archiver, which ships it at once. `archive_timeout` (300 s) closes a
  segment every 5 minutes even if it isn't full, so a quiet database still
  has at most 5 minutes unarchived. An idle database writes almost nothing.
- **Layout in the bucket:** `s3://pg-backups/pg/wals/` (seen 2026-11-02,
  the first WAL a minute after the apply) and `s3://pg-backups/pg/base/<backup
  id>/` (seen 2026-11-03: `20261103T184539/`, 2 objects, 185 MiB for the
  ~1.4 GB database; taken from replica pg-1 in 51 s). `pg` is the cluster's name (the
  "server name").
- **Applying it** restarts every instance (the new sidecar): replicas first,
  then a switchover, as for a patch (runbook 13).
- **Gap:** the plugin Deployment runs one copy (its chart supports only
  that). While it's down, instances keep archiving, but new instance pods
  can't be created. Not yet tested under a zone loss (runbook 26).

### MySQL: the Percona operator's backups

- Built into the PXC operator: the `backup` section of the
  `PerconaXtraDBCluster` (`relational/modules/mysql/cluster/main.tf`).
- **Full backups:** the backup Job joins the Galera cluster as an
  arbitrator (`garbd`, no data) and asks for a full state transfer (SST),
  as a new node would. A node that is not the writer becomes the **donor**:
  it runs **Percona XtraBackup** (the copy bundled in its own PXC image),
  which copies the InnoDB data files while the node keeps serving, plus the
  redo log written meanwhile, so the copy is consistent. The Job receives
  the stream and **xbcloud** uploads it to the bucket, one object per file
  chunk, uncompressed. Seen 2026-11-03: donor mysql-pxc-2 (writer pxc-0),
  desynced 32 s at 41-48 MiB/s; 71 s in all; 775 MiB in 351 objects under
  `s3://mysql-backups/mysql-<date>-<time>-full/`.
- **Versions:** the PXC 8.0.46 image bundles XtraBackup 8.0.35-36 (and
  2.4 for 5.7), so Percona pairs them; the Job's image
  (`percona-xtrabackup:8.0.35-36.1`, the last 8.0 build) only receives and
  uploads. Both move to 8.4 with the server (runbook 14).
- **Schedule and retention:** each Sunday 03:00 UTC (`0 3 * * 0`); the
  operator keeps the last 2 scheduled backups and deletes older ones from
  the store too. Backups made on demand (`PerconaXtraDBClusterBackup`) are
  kept until their resource is deleted.
- **Point-in-time recovery:** the `mysql-pitr` Deployment, the binlog
  collector, uploads each binary log to the bucket, at least every 60 s.
  PITR needs GTIDs (`gtid_mode=ON`, which PXC sets) and row-based binlogs
  (`ROW`): both checked on 2026-10-30. It reads the binlogs from one node
  (as the `xtrabackup` user, through the `mysql-pxc` service) and keeps track
  of the last GTID set it uploaded, so a restart resumes where it stopped.
- **Its memory:** the operator gives the collector an upload buffer of 75%
  of its memory limit (`BUFFER_SIZE`). At a 256 Mi limit it was OOMKilled
  uploading a 266 MB binlog (the 3,000,000-row seed's, 2026-11-02); the
  limit is now 1 Gi, Percona's example. It still died twice on that file
  (a 768 MiB buffer leaves about 256 MiB for everything else) but resumed
  each time and caught up in 2 minutes. Normal binlogs are a few MB.
- **A new binlog every minute:** to upload the binlog the server is still
  writing, the collector runs `FLUSH BINARY LOGS` every
  `timeBetweenUploads` (60 s), which closes it and starts the next. When
  nothing was written the new file is empty (241 bytes) and not uploaded,
  but it stays on the node the collector reads from (mysql-pxc-0 on
  2026-11-02: 35 binlogs, against 7 and 9 on the others) until
  `binlog_expire_logs_seconds`. MySQL's default is 30 days (up to 43,200
  small files); the cluster module sets 7 days (up to 10,080). Nothing is
  lost: once uploaded, the store's copy is the one a restore uses, so the
  node only needs its binlogs while the collector catches up. Otherwise a
  binlog grows to `max_binlog_size` (1 GiB) before a new one starts.
- **The S3 settings** for an S3-compatible store: `endpointUrl`, a
  `region` (only used to sign requests), and `forcePathStyle: true`
  (`<endpoint>/<bucket>/…`, not `<bucket>.<endpoint>`).

## What it costs

- **Disk:** each database is about 1.4 GB on disk; a compressed full backup
  should be well under that, plus the logs. The Mac had 16 GiB free on
  2026-10-30, hence weekly fulls and short retention.
- **Memory:** cert-manager ~160 Mi requested, the plugin 64 Mi, a 128 Mi
  sidecar per pg instance, the binlog collector 128 Mi (up to 1 Gi while it
  uploads a large binlog); a backup Job 256 Mi while it runs.

## Bring it up

From the repo root, after the platform cluster:

```sh
# 1. the store (once; it survives cluster rebuilds)
private/datastore-clusters/platform/scripts/backup_store_keys.sh
cd private/datastore-clusters/platform/environments/dev/backup-store
terraform init && terraform plan -out plan-backup-store && terraform apply plan-backup-store

# 2. cert-manager
cd ../services
terraform init && terraform plan -out plan-services && terraform apply plan-services

# 3. the plugin
cd ../../../../relational/environments/dev/operators
terraform init && terraform plan -out plan-operators && terraform apply plan-operators

# 4. the keys as Secrets, then the clusters' backup settings
../../../scripts/backup_secrets.sh
cd ../clusters
terraform init && terraform plan -out plan-clusters && terraform apply plan-clusters

private/datastore-clusters/platform/scripts/check_resources.sh
private/datastore-clusters/relational/scripts/check_resources.sh   # the backups section
```

## Look at it

```sh
export KUBECONFIG=~/.kube/kind-datastore-dev
kubectl -n relational get objectstores,scheduledbackups,backups          # PostgreSQL
kubectl -n relational get clusters.postgresql.cnpg.io pg \
  -o jsonpath='{.status.conditions[?(@.type=="ContinuousArchiving")]}'    # WAL archiving
kubectl -n relational get pxc-backup,pxc-restore                          # MySQL
kubectl -n relational logs deploy/mysql-pitr                              # binlog uploads
kubectl -n cnpg-system logs deploy/plugin-barman-cloud                    # the plugin
```

The bucket itself, from the laptop, with the key printed nowhere: the
relational `check_resources.sh` counts WAL files in `s3://pg-backups/pg/wals/`
(its `store_count` helper reads the key file and hands curl the key on stdin).

## Take one by hand

One full backup now, outside the weekly schedule (before a risky change, or
to see how long one takes):

```sh
private/datastore-clusters/relational/scripts/backup_now.sh pg      # PostgreSQL
private/datastore-clusters/relational/scripts/backup_now.sh mysql   # MySQL
```

Each creates a backup resource, waits for it, and prints how long it took,
where it is in the store and its size; the run is logged in
`relational/logs/backup-<engine>-<time>.txt`. The resources it creates,
should you write them yourself:

| | PostgreSQL | MySQL |
|---|---|---|
| Resource | `Backup` (`postgresql.cnpg.io/v1`) | `PerconaXtraDBClusterBackup` (`pxc.percona.com/v1`) |
| Spec | `cluster.name: pg`, `method: plugin`, `pluginConfiguration.name: barman-cloud.cloudnative-pg.io`, `target: prefer-standby` | `pxcCluster: mysql`, `storageName: s3` |
| Done when | `status.phase: completed` | `status.state: Succeeded` |
| Where | `s3://pg-backups/pg/base/<status.backupId>/` | `status.destination` |
| List them | `kubectl -n relational get backups` | `kubectl -n relational get pxc-backup` |

Backups taken by hand stay until deleted: MySQL's "keep 2" counts only
scheduled ones. Deleting a MySQL backup resource deletes it from the store
too (the `percona.com/delete-backup` finalizer the script sets).

## Restore (runbook 8 scripted; runbook 9 to script)

- **PostgreSQL:** a **new** Cluster that bootstraps from the store:
  `bootstrap.recovery.source` names an `externalClusters` entry using the
  plugin, with `barmanObjectName: pg-backups` and `serverName: pg`. For PITR,
  `recoveryTarget.targetTime` (or a transaction id, an LSN, or a named
  restore point). If the new cluster archives too, it must use a different
  server name: CloudNativePG refuses to archive into a location that already
  holds another cluster's WAL.
- **MySQL:** a `PerconaXtraDBClusterRestore` naming the cluster and either
  a backup (`backupName`) or a location in the store (`backupSource`), with
  `pitr` for a date or a GTID. It replaces the cluster's data: the cluster
  stops, the backup is copied in, the binlogs are replayed, the nodes
  rejoin. **Never point one at the live cluster in the lab:** runbook 8
  restores into a separate one-node cluster, `mysql-restore`, which needs
  a copy of the live cluster's system passwords (`mysql-secrets`): the
  backup's `mysql.user` holds them, and the operator could not log in
  with new ones. `backupSource` must carry the store's S3 settings inline
  (`s3: {bucket, credentialsSecret, endpointUrl, region, forcePathStyle}`):
  with only `storageName`, operator 1.20 fails "nil s3 backup status
  storage". Its steps, as seen: Stopping Cluster, Restoring (copy from the
  store), Preparing Cluster (XtraBackup applies the redo log), Starting
  Cluster, Succeeded.
- **Runbook 8** (`relational/scripts/runbook_8_restore.sh pg|mysql`): a
  fresh backup, then a restore into `<engine>-restore` beside the live
  cluster. It compares a fingerprint of every row with the source, checks
  the indexes and tables, runs the app's queries against it, then deletes it.
  Test plan: [../test_plans/runbook-08-restore.md](../test_plans/runbook-08-restore.md).
- Runbook 9 (point in time) will check the result against k6's tagged rows:
  every order acknowledged before the target is there, nothing after it.

## Known gaps

- The store is on the same laptop as the cluster: a lost laptop loses both.
  On a cloud the store would be in another account and region.
- No object lock (immutable backups) and no encryption at rest yet.
- The plugin Deployment is a single copy (above).
- No "last good backup is too old" alert yet (runbook 7's check).
- No restore has been tested yet: until then these are untested backups.

## Glossary

| Term | Meaning |
|---|---|
| WAL | PostgreSQL's write-ahead log: every change, written before the data files; 16 MB segments |
| binlog | MySQL's binary log: every committed change, in commit order; what replication and PITR replay |
| GTID | MySQL's global transaction id: names each transaction, so a replay knows exactly where to stop |
| base / full backup | a physical copy of the whole database at one point |
| PITR | point-in-time recovery: a full backup plus logs replayed to a chosen moment |
| RPO / RTO | how much data may be lost / how long recovery may take |
| object store, bucket | storage for whole files ("objects") over HTTP; a bucket is a named container of them |
| S3 API, SigV4 | Amazon's object storage protocol, which other stores copy; requests are signed with the key (Signature Version 4) |
| path style | `http://host/bucket/key` addressing, which local stores use, versus `http://bucket.host/key` |
| CRD | custom resource definition: a new kind of Kubernetes object, such as ObjectStore or Certificate |
| sidecar | an extra container in a pod, beside the main one, sharing its disk and network |
| mTLS | mutual TLS: both sides of a connection present certificates |
