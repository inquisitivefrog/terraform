# Runbook 1: monitor (alerts fire and clear)

**Purpose:** prove each tested alert rule fires on a real fault, reaches
Alertmanager, and clears when the fault is undone. The rules live in
`relational/modules/*/cluster/alerts.tf` and
`relational/modules/orders-app/alerts.tf`.

**Run:** `relational/scripts/runbook_1_alerts.sh pg|mysql [rate=20] [duration] [dev]`
(duration defaults: 15m pg, 20m mysql). Repeatable: every trigger is undone.

## Preconditions

- Cluster whole; the rules are loaded in Prometheus; none of them firing.

## Steps and what each must show

| Step | pg trigger | mysql trigger | Alert that must fire |
|---|---|---|---|
| 2. Member down | fence a replica (`cnpg.io/fencedInstances`) | SIGSTOP a non-writer's mysqld from its node (again after each kubelet restart): a hung node | `PostgreSQLInstanceDown` / `MySQLMemberDown` |
| 3. Replication lag | `pg_wal_replay_pause()` on a replica | desync a non-writer and hold `FLUSH TABLES WITH READ LOCK` | `PostgreSQLReplicationLag` / `MySQLApplyQueue` |
| 4. Connections over 80% | a pod holds idle connections to a replica, 85% of max_connections | same | `PostgreSQLConnectionsHigh` / `MySQLConnectionsHigh` |
| 5. Latency SLO (search) | pg meets the SLO: the alert must stay quiet | the planted missing index: must fire under load, clear after the load ends | `OrdersLatencySLO` |

For each test: trigger, wait for the alert to be firing in Prometheus and
present in Alertmanager, undo, wait for it to be neither firing nor pending,
wait for the cluster to be whole.

## Pass criteria

- Each alert fires within **300 s** (FIRE_WAIT) and clears within **420 s**
  (CLEAR_WAIT; the SLO alert uses a 5 m rate window).
- pg: `OrdersLatencySLO` never fires.
- No acknowledged write lost; `check_resources.sh` passes.
- The k6 run itself may report FAILED on mysql (search threshold crossed by
  design, and a few writes fail while a node is frozen): the runbook judges
  the alerts and lost writes, not k6's thresholds.

## Expected (lab, 2026-10-30)

| Alert | Fired after | Cleared after the undo |
|---|---|---|
| PostgreSQLInstanceDown | 91 s | 31 s |
| PostgreSQLReplicationLag | 152 s | 61 s |
| PostgreSQLConnectionsHigh | 111 s | 61 s |
| OrdersLatencySLO (pg) | stayed quiet | — |
| MySQLMemberDown | 111 s | 91 s |
| MySQLApplyQueue | 112 s | 61 s |
| MySQLConnectionsHigh | 112 s | 31 s |
| OrdersLatencySLO (mysql) | firing under load | 302 s after the load ended |

pg k6: 0 of 18,001 failed. mysql k6: 12 creates, 1 read and 36 searches failed (the
frozen node), 0 lost. `check_resources.sh` 45/45 at the time (50 now).
Logs: `runbook-1-pg-20261030-023700.txt`, `runbook-1-mysql-20261030-025556.txt`.

## Not covered

- Primary or quorum loss (runbooks 24 and 27 cover the event; their alerts
  aren't fired here), memory, disk, certificates, backups: no safe trigger in
  the lab yet.
- Alertmanager's receiver is still `null`: the test proves an alert reaches
  Alertmanager, not that anyone is told.
