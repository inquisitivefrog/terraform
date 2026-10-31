# Runbook 13: security patch (minor version)

**Purpose:** move every member to a new minor release under load, one at a
time, through Terraform, with seconds of app errors at most and nothing
acknowledged lost.

**Run:**
1. Set the new image in `relational/environments/dev/clusters/variables.tf`
   (`postgres_image` or `pxc_image`). The script reads its target from there.
2. `relational/scripts/runbook_13_patch.sh pg|mysql [rate=20] [duration=15m] [dev]`
3. When it asks, apply the clusters root in a second terminal:
   `terraform plan -out plan-clusters` (expect 1 to change), then
   `terraform apply plan-clusters`.

## Preconditions

- Cluster whole; the app's pods exist.
- pg: `primaryUpdateMethod` is `switchover` (otherwise the primary restarts
  in place and the app sees an outage, not a switchover).
- No member already runs the target image.

## Steps and what each must show

1. k6 load starts (60 s to settle).
2. A member changes to the target image within **10 min** of the prompt
   (else: the apply didn't happen).
3. Rollout, all 3 members back and ready on the new image within **15 min**,
   then the cluster is whole within 5 min.
   - pg: CloudNativePG updates the replicas one at a time, switches over to
     one of them, then updates the old primary.
   - mysql: PXC SmartUpdate restarts the nodes one at a time, the writer
     last; HAProxy moves writes to another node meanwhile.
4. Every member reports the new version from inside the server
   (`SHOW server_version` / `SELECT @@version`).
5. What the app saw.

## Pass criteria

- The app's errors (first to last failed create/update/delete/read; search
  left out) last at most **30 s** (BUDGET).
- 0 acknowledged writes lost; nothing fails from 30 s after the last member is
  back.
- `check_resources.sh` passes.

## Expected (lab, 2026-10-30)

| | pg | mysql |
|---|---|---|
| Versions | 16.13 → 16.15 | 8.0.44 → 8.0.46 |
| Rollout, first change to whole | 188 s | 347 s |
| Order | replicas, then switchover, then the old primary | mysql-pxc-2 (+100 s), mysql-pxc-1 (+222 s), writer mysql-pxc-0 (+336 s) |
| Writer | moves once (switchover) | moves to mysql-pxc-2, then back to mysql-pxc-0 |
| App errors | ~5 s | ~20 s (as the writer stopped; 65 of 17,880 requests) |
| Lost | 0 | 0 |

Logs: `runbook-13-pg-20261030-214814.txt`, `runbook-13-mysql-20261030-221209.txt`.

## Caveats and findings

- **pg before the fix:** the default `primaryUpdateMethod: restart` restarts
  the primary in place: an outage. Set to `switchover` in
  `relational/modules/postgresql/cluster/main.tf`.
- **Repeat runs:** PostgreSQL can go back a minor (same on-disk format), so
  the pg run can alternate. MySQL 8.0 can't downgrade a minor: on mysql the
  run only moves forward, or rebuild the clusters root.
- Current defaults: pg `16.15-standard-trixie`, PXC `8.0.46-38.1`. The major
  upgrades (to PG 18 and PXC 8.4) are runbook 14, not this one.
