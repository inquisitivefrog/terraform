# Runbook 25: reader failure

**Purpose:** kill a replica's pod under load and prove it costs read capacity
only: no write fails, nothing is lost, reads are normal once it is back.

**Run:** `relational/scripts/runbook_25_reader.sh pg|mysql [rate=20] [duration=5m] [dev]`.
Repeatable: the replica comes back by itself.

## Preconditions

- Cluster whole; pick the replica:
  - pg: a CloudNativePG replica. Quorum commit is ANY 1 of 2, so the other
    replica acknowledges commits while it is down.
  - mysql: a Galera node HAProxy isn't sending writes to. Every node votes;
    2 of 3 keep the cluster primary.

## Steps and what each must show

1. k6 load starts (60 s to settle).
2. Delete the replica's pod.
3. **Back and caught up:** pg 2 replicas streaming; Galera 3 members Synced
   and the operator ready (prints how long it took).
4. What the app saw.

## Pass criteria

- **No write fails at all**; 0 lost.
- Reads may fail while the reader endpoint drops the replica (counted), but
  none from **30 s** after it is back.
- The writer is unchanged.
- `check_resources.sh` passes.

## Expected (lab, 2026-10-30)

| | pg | mysql |
|---|---|---|
| Deleted | pg-2 (a replica) | mysql-pxc-1 (a non-writer) |
| Writes failed / lost | 0 / 0 | 0 / 0 |
| Reads failed | 0 | 0 |
| Writer | unchanged | unchanged |
| App restarts | 0 | 0 |

Logs: `runbook-25-pg-20261030-225749.txt`, `runbook-25-mysql-20261030-230315.txt`.
