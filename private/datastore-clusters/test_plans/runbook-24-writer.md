# Runbook 24: writer failure (unplanned election)

**Purpose:** kill the writer's pod under load and prove the cluster recovers
by itself within the RTO, with no acknowledged write lost.

**Run:** `relational/scripts/runbook_24_writer.sh pg|mysql [rate=20] [duration=5m] [dev]`.
Repeatable: the cluster heals; the writer stays wherever the election put it.

## Preconditions

- Cluster whole.

## Steps and what each must show

1. k6 load starts (60 s to settle).
2. **Kill the writer** (`failover_test.sh <engine> pod`). A probe writes once
   a second through the writer endpoint, each on a new connection, and times
   the outage.
   - pg: CloudNativePG waits failoverDelay (5 s), then promotes the replica
     holding every acknowledged commit, unless the restarted primary is back
     first and keeps its role.
   - mysql: no election; HAProxy sends writes to the next healthy node.
3. **The old writer is back as a member:** pg 2 replicas streaming; Galera 3
   members Synced and the operator ready.
4. What the app saw.

## Pass criteria

- The probe's write outage is within **60 s** (RTO).
- 0 acknowledged writes lost (RPO 0).
- No write or read fails from **30 s** after the probe's writes recover until
  the load ends.
- `check_resources.sh` passes.

## Expected (lab, 2026-10-30)

| | pg | mysql |
|---|---|---|
| Killed | pg-2 | mysql-pxc-0 |
| New writer | pg-1 | next HAProxy backend |
| Probe outage | ~17 s | ~0 s |
| App writes failed | 0 (the app's retries covered it) | 0 |
| Lost | 0 | 0 |
| App restarts | 0 | 0 |

Logs: `runbook-24-pg-20261030-224650.txt`, `runbook-24-mysql-20261030-225215.txt`.

## Caveats

- A pod kill isn't a node loss: the node stays up, so Kubernetes and the
  operator see the failure at once. Node and zone loss, where detection waits
  on the node grace period, is runbook 26.
