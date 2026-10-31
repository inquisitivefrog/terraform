# Runbook 23: planned switchover

**Purpose:** move the writer on purpose under load, prove the clients follow
it and nothing is lost, then move it back.

**Run:** `relational/scripts/runbook_23_switchover.sh pg|mysql [rate=20] [duration=6m] [dev]`.
Repeatable: it ends with the writer where it started.

## Preconditions

- Cluster whole; note the writer and pick a target.

## Steps and what each must show

1. k6 load starts (60 s to settle).
2. **Switch over:**
   - pg: CloudNativePG switchover to a replica (what `kubectl cnpg promote`
     does). The primary shuts down, the target is promoted once it has
     replayed everything, and the old primary rejoins as a replica.
   - mysql: `pxc_maint_mode=MAINTENANCE` on the writer: its health check
     fails, HAProxy sends writes to the next node, the node stays in the
     cluster.
3. 60 s on the new writer: no write fails from 30 s after the switch.
4. **Switch back:** pg promotes the old primary; mysql sets
   `pxc_maint_mode=DISABLED` and HAProxy returns to the node.
5. What the app saw.

## Pass criteria

- 0 acknowledged writes lost.
- No write or read fails from **30 s** (SETTLE) after each switch.
- Exactly one writer at the end, the original.
- `check_resources.sh` passes.

## Expected (lab, 2026-10-30)

| | pg | mysql |
|---|---|---|
| Path | pg-2 → pg-1 → pg-2 | maintenance mode on the writer and back |
| Time to a new writer (out / back) | 19 s / 18 s | 19 s / 1 s |
| Writes failed | 14, none after 30 s | 0 |
| Lost | 0 | 0 |
| App restarts | 0 | 0 |

Logs: `runbook-23-pg-20261030-223255.txt`, `runbook-23-mysql-20261030-224015.txt`.

## Caveats

- pg's few failed writes are the primary's shutdown window; the app's
  retries cover most of it. mysql's maintenance mode drains with no errors.
