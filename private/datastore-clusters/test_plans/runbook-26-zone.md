# Runbook 26: zone outage

**Purpose:** lose the writer's whole zone under load and prove writes resume
within the RTO, nothing acknowledged is lost, and the zone rejoins when it
comes back. In this lab one zone is one node container.

**Run:** `relational/scripts/runbook_26_zone.sh pg|mysql [rate=20] [duration=6m] [dev]`.
Repeatable: the zone returns and the cluster heals; the writer stays wherever
the election put it.

## Preconditions

- Cluster whole; find the writer's zone.
- The log prints where the operators' copies and the app's pods are, and
  whether an app pod is in the lost zone. The scheduler places them, so the
  **worst case** (an app pod in the lost zone) may take reruns to come up.
  Each case that has passed is listed below.

## Steps and what each must show

1. k6 load starts **outside** that zone (`K6_AVOID_ZONE`; the users aren't in
   the datacenter), 60 s to settle.
2. `failover_test.sh <engine> zone`: `docker stop` the zone's node. A probe
   in another zone writes once a second on a new connection and times the
   outage. Then the node starts again and the test waits for every member to
   be ready.
3. What the app saw.
4. Both outages are judged against the RTO.

## Pass criteria

- The probe's outage (the database) is within **60 s** (RTO).
- The app's outage (first to last failed create/update/delete/read in k6;
  search left out) is within **60 s**. This includes Kubernetes dropping the
  dead zone's app pod from the Service.
- 0 acknowledged writes lost (RPO 0).
- No write or read fails from **30 s** after the probe's writes recover until
  the load ends.
- `check_resources.sh` passes.

## How the failover happens

- **The node is noticed** after node-monitor-grace-period (20 s in this lab;
  default 40 s).
- **pg:** the CloudNativePG operator decides the failover, not the
  instances. After failoverDelay (5 s) it promotes a replica. If the
  operator's only copy is in the lost zone, nothing fails over until
  Kubernetes evicts it (300 s). Hence 2 copies in different zones, with
  leader election on a 15 s lease.
- **mysql:** Galera keeps quorum with 2 of 3 and HAProxy health checks move
  writes; no operator needed for that. The operator is still needed for
  recovery after a lost quorum, healing, backups and certificates, so it
  also runs 2 copies spread by zone, with its lease cut from 60 s to 15 s.

## Expected (lab, 2026-10-30)

| Case | pg | mysql |
|---|---|---|
| Worst case: writer and an app pod in the lost zone | pg-2 → pg-1 in 26 s; database ~30 s; app ~40 s | mysql-pxc-0 → mysql-pxc-2 in 22 s; database ~17 s; app ~40 s |
| Leading operator copy in the lost zone (standby takes the lease) | failover 30 s; database ~35 s | — |
| No app pod in the lost zone | app ~25 s | app ~10 s |

All passes: 0 lost, 50/50. App peak working set 323–355 MiB of 768.

Logs (worst case): `runbook-26-pg-20261030-233815.txt`,
`runbook-26-mysql-20261030-233139.txt`. Earlier cases survive only in
`private/docs/STATUS.md` and RUNBOOKS.md (their logs were replaced).

## Findings that shaped the design

1. **Operator in the lost zone (pg):** writes didn't recover in 5 min. Fix:
   2 operator copies with required zone anti-affinity (both engines).
2. **App outage inflated to ~60 s:** k6 waited 30 s (its default) on a
   connection to the dead app pod. Fix: a 15 s request timeout in `orders.js`,
   above the app's ~13 s retry budget. Requests stuck on the dead pod now
   fail at 15 s with `request timeout`.
3. **App OOMKill under the failover pile-up:** heap 60% of 512Mi plus
   ~215 MiB non-heap. Fix: 768Mi with heap 50% (orders 0.1.3).
4. **Node detection:** node-monitor-grace-period cut to 20 s in the kind
   cluster config (`platform/modules/kind-cluster`).

## Known issue

- The lost zone's app pod exits 1 twice on startup when its node returns
  (it can't reach the database yet), then starts: 2 app restarts per run, on
  both apps. Not a failure; not fixed yet.
