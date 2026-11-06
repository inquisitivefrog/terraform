# private/datastore-clusters

## Purpose

Run highly available datastores the way a team would run them itself, and
prove the day-2 work: break things on purpose under live load and check
that nothing acknowledged is lost, alerts fire, and service recovers in
time. Built on a laptop (Docker Desktop + kind, three simulated zones),
because the same designs in AWS cost more than the Free plan allows.

## Datastores

- **PostgreSQL 16**: CloudNativePG operator, 3 instances (1 writer,
  2 replicas). Running.
- **MySQL 8.0**: Percona XtraDB Cluster (Galera), 3 nodes behind HAProxy.
  Running.
- Planned, one category at a time: distributed SQL, in-memory, search,
  time-series, NoSQL, vector, graph, object storage and analytics,
  directory.

Each has an example orders app, k6 load, Prometheus metrics, Grafana
dashboards, alerts, and encrypted, locked backups.

## Runbooks

Scripted, and passing on both engines:

| # | Runbook | In simple terms |
|---|---|---|
| 1 | Monitor | Trigger each problem and check its alert fires |
| 5 | Load test | Measure normal speed, to compare against (pg only) |
| 7 | Back up | Take backups by hand and on schedule, and check they are encrypted and can't be deleted early |
| 8 | Restore | Rebuild the database from a backup into a new cluster |
| 9 | Point-in-time recovery | Undo a bad delete by restoring to the moment before it |
| 12 | Backup storage check | Confirm backups exist, are recent, and old ones are cleaned up |
| 13 | Security patch | Move to a newer minor version, one member at a time |
| 16 | Tune configuration | Change a setting with a rolling restart, and measure the effect |
| 17 | Schema change | Add an index while the app keeps running |
| 22 | Replace a damaged node | Throw away a member's disk and rebuild it from the others |
| 23 | Planned switchover | Move the writer on purpose, then back |
| 24 | Writer failure | Kill the writer; another member must take over |
| 25 | Reader failure | Kill a replica; reads must carry on |
| 26 | Zone outage | Lose a whole zone; the cluster must keep serving |

Next: 14, major version upgrade. The other 26 (capacity, disaster
recovery, quorum loss, disk full, credential rotation and more) are
defined but not scripted.

## Docs

- [docs/PLATFORM.md](docs/PLATFORM.md): layout, every category and engine,
  rules, platform build and teardown.
- [docs/RUNBOOKS.md](docs/RUNBOOKS.md): all 40 runbooks, step by step.
- [test_plans/](test_plans/README.md): what each scripted runbook must
  show, and what was measured.
- [docs/BACKUPS.md](docs/BACKUPS.md): how backups work.
- [docs/DESIGN.md](docs/DESIGN.md): why it is shaped this way.
- [relational/](relational/README.md): the PostgreSQL and MySQL clusters
  and the orders app.
