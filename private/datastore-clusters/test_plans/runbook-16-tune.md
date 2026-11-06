# Runbook 16: tune configuration

**Purpose:** change one setting through Terraform, let the operator roll it
out under load, and measure what it changed: the same fixed-rate load three
times before and three times after. The effect is reported, not judged: a
change that does nothing measurable is a result too.

**Run:**
1. `relational/scripts/runbook_16_tune.sh pg|mysql before [rate=20] [duration=5m] [dev]`
   (about 16 min; saves `relational/logs/runbook-16-<engine>-before.tsv`).
2. Change the setting in `relational/environments/dev/clusters/main.tf`.
3. `relational/scripts/runbook_16_tune.sh pg|mysql after` and, when it asks,
   apply the clusters root in a second terminal: `terraform plan -out
   plan-clusters` (expect 1 to change: that engine's cluster), then
   `terraform apply plan-clusters`. About 30 min for pg, 45 for mysql.

The settings it watches: pg `shared_buffers`, mysql `gcache.size` (written
as `wsrep_provider_options="pc.weight=10;gcache.size=..."` by the mysql
module's `gcache_size`: that line replaces the operator's, so its
`pc.weight=10` is repeated).

## Steps and what each must show

**before**
0. The cluster is whole; every member has the same value.
1. Three loads, each measured and saved. A load with a missing column fails.

**after**
0. A complete before file; the setting still has its before value.
1. A k6 load (pg 15m; mysql 25m) and the prompt to apply. The rollout must
   start within **10 min** and every member be back with the new value
   within **15 min**, then the cluster whole within 5 min. A member that goes
   down again (no answer, or a new pod) is unmarked and its down time summed;
   the rollout ends once every member has been back for 30 s.
   - pg: replicas restarted, a switchover, the old primary restarted.
   - mysql: every node restarted (SmartUpdate, the writer last). Each must
     rejoin by **IST**; an SST fails the run.
2. mysql only: `innodb_buffer_pool_size` resized online (SET GLOBAL, 768M ->
   512M -> back) on a node that is not the writer; the configuration still
   says 768M.
3. What the app saw: errors last at most **30 s**; **0 acknowledged writes
   lost**; nothing failed from 30 s after the rollout.
4. Three loads, measured; before and after side by side (median of 3).
5. Verify: relational `check_resources.sh` passes.

Measured per load: search and create p95, failed, lost; pg blocks read from
outside shared_buffers (all instances), per search, and the hit ratio;
mysql the write-set rate, the IST window (gcache.size / that rate) and
InnoDB disk reads.

## Pass criteria

- Rollout within the time limits; mysql: every node by IST.
- App errors at most 30 s, 0 lost, none after the cutoff.
- `check_resources.sh` passes.

## Measured (lab, 2026-11-05, ~3,000,000 orders, 20 requests/s)

| | pg: shared_buffers 128MB -> 256MB (and 512Mi -> 768Mi) | mysql: gcache 128M -> 512M |
|---|---|---|
| Rollout | 85 s; replicas ~27 s each; switchover pg-1 -> pg-3 | 161 s; each node ~40 s; all IST |
| Writer moves | 1 (switchover) | 2: pxc-0 -> pxc-2, then back when pxc-0 returned (HAProxy fails back) |
| App during the rollout | 2 writes failed (~5 s), 0 lost | 0 failed, 0 lost; slowest write ~2.3 s |
| Search p95 | 72.4 -> 59.1 ms (-18%) | 828.6 -> 992.5 ms (+20%); 806 ms on 11-06 (the host, not gcache) |
| Cache | hit ratio 42.6% -> 84.1%; blocks read outside shared_buffers per search -72% | IST window 10.8 -> 43.4 h at 3.4 KiB/s of write-sets |
| Online resize (mysql) | - | 768M -> 512M -> 768M in ~1 s, no restart |

The pg hit ratio is about shared_buffers / table size both times (16,384 /
38,900 and 32,768 / 38,900 pages): concurrent scans and parallel workers
keep the table cached despite the 256 KB ring buffer meant for large
scans. The mysql search slowdown is not memory or disk (CPU per row +8%,
more of the scanning on the writer); it fell over the three loads (992,
1,021, 913 ms) and is likely the restarts, not gcache.
Settled 2026-11-06: it was the Mac. By that night search p95 was 1,290 ms
at the same rows read (~12 M/s) with 35% more CPU per row on every node;
after a reboot, with torrents and the VPN off, it was 806 ms at 0.217
cores per M rows/s (0.219 before the change). Compare loads only with the
Mac otherwise idle.

Logs: `runbook-16-pg-after-20261105-010247.txt`,
`runbook-16-mysql-after-20261105-181729.txt`, and the two `-before.tsv`
files.

## Caveats

- Numbers are relative only (before/after on the same laptop), never a
  capacity figure.
- pg's change also raised the memory limit, so the page cache had more room
  too; the effect is both.
- Keep the Mac awake: an idle sleep freezes the Docker VM (the runbooks now
  run `caffeinate`; closing the lid still sleeps).
