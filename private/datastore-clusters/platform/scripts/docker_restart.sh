#!/bin/bash
# Bring the stopped kind cluster back (after a reboot, or after
# docker_shutdown.sh), wait until each layer is really up, then run both
# checks. Safe to run when everything is already running.
#
# Every wait looks for evidence newer than the restart. Status saved before
# the shutdown (node Ready, pod ready, the PXC and CloudNativePG cluster
# states) still reads healthy for the first minute, until the controllers
# catch up, so waiting on it proves nothing.
#
# After all three Galera nodes stopped together, the PXC operator runs its
# full-cluster crash recovery: it bootstraps the node with the highest
# committed sequence number and the others rejoin by IST (2026-10-27: about
# 3.5 minutes from Docker start to 3 members).

set -uo pipefail
CLUSTER="datastore-dev"
CTX="kind-$CLUSTER"
KCFG="$HOME/.kube/kind-$CLUSTER"
DIR="$(cd "$(dirname "$0")/../.." && pwd)" # private/datastore-clusters
k() { kubectl --kubeconfig "$KCFG" --context "$CTX" "$@"; }

# wait_for <label> <seconds> <command...>: retry every 5 s until it succeeds
wait_for() {
  local label="$1" limit="$2" start=$SECONDS
  shift 2
  printf '%s ' "$label"
  until "$@" >/dev/null 2>&1; do
    if ((SECONDS - start >= limit)); then
      echo "gave up after ${limit}s"
      return 1
    fi
    printf '.'
    sleep 5
  done
  echo "ok ($((SECONDS - start))s)"
}

# Every node is Ready and its kubelet has renewed its Lease (every 10 s)
# since the restart. The Ready condition's own heartbeat time refreshes only
# about every 5 minutes while nothing changes, so it can't show freshness.
nodes_fresh() {
  [[ -z "$(k get nodes --no-headers | awk '$2 != "Ready"')" ]] || return 1
  k -n kube-node-lease get leases -o json | python3 -c '
import json, sys
since = sys.argv[1]
leases = [l for l in json.load(sys.stdin)["items"] if l["metadata"]["name"].startswith(sys.argv[2])]
sys.exit(0 if len(leases) == 4 and all(l["spec"]["renewTime"] >= since for l in leases) else 1)' "$T0" "$CLUSTER-"
}

# Every pod is Running with all containers ready and started after the
# restart (restarting a node container restarts every container on it).
pods_fresh() {
  k get pods -A -o json | python3 -c '
import json, sys
since = sys.argv[1]
for p in json.load(sys.stdin)["items"]:
    # Finished Job pods never run again (a k6 run that misses its SLO ends
    # Failed). A crash-looping pod is still Running, so it is not skipped.
    if p["status"].get("phase") in ("Succeeded", "Failed"):
        continue
    cs = p["status"].get("containerStatuses", [])
    if p["status"].get("phase") != "Running" or not cs:
        sys.exit(1)
    for c in cs:
        started = c.get("state", {}).get("running", {}).get("startedAt", "")
        if not c.get("ready") or started < since:
            sys.exit(1)' "$T0"
}

# Every Galera node sees all three members and is Synced.
galera_whole() {
  local pw p out
  pw="$(k -n relational get secret mysql-secrets -o jsonpath='{.data.root}' | base64 -d)"
  for p in 0 1 2; do
    out="$(k -n relational exec -i "mysql-pxc-$p" -c pxc -- sh -c 'read -r MYSQL_PWD; export MYSQL_PWD; exec mysql -uroot -NBe "$0"' \
      "select group_concat(variable_value order by variable_name separator ' ') from performance_schema.global_status where variable_name in ('wsrep_cluster_size','wsrep_local_state_comment')" <<<"$pw")"
    [[ "$out" == "3 Synced" ]] || return 1
  done
}

# The operator reports the cluster ready with all three nodes. Checked after
# galera_whole, so the status is newer than the restart: the joiners restart
# once more to rejoin by IST, and Galera reads "3 Synced" a few seconds
# before their readiness probes and the operator catch up.
pxc_ready() {
  [[ "$(k -n relational get pxc mysql -o jsonpath='{.status.state} {.status.pxc.ready}')" == "ready 3" ]]
}

# The primary has both replicas streaming (local socket, as postgres).
pg_streaming() {
  local primary
  primary="$(k -n relational get pods -l cnpg.io/cluster=pg,cnpg.io/instanceRole=primary -o jsonpath='{.items[0].metadata.name}')"
  [[ "$(k -n relational exec "$primary" -c postgres -- psql -tAc "select count(*) from pg_stat_replication where state = 'streaming'")" == 2 ]]
}

# Count of series for a PromQL expression scraped in the last minute.
fresh_count() {
  local q n
  q="count($1 == 1 and (time() - timestamp($1)) < 60)"
  n="$(k get --raw "/api/v1/namespaces/monitoring/services/kube-prometheus-stack-prometheus:http-web/proxy/api/v1/query?query=$(printf %s "$q" | jq -sRr @uri)" |
    grep -oE '"[0-9]+"\]' | tr -dc '0-9')"
  echo "${n:-0}"
}

# Prometheus has scraped every database exporter since the restart, each
# MySQL exporter has logged in to its node (up is 1 even when it can't), and
# no target anywhere is down: the app pods restart until their database is
# back, and the platform check fails on any down target (three restarts in a
# row showed "36 up, 1 down" for a few seconds, 2026-10-28).
scraped() {
  [[ "$(fresh_count 'up{namespace="relational"}')" -ge 6 ]] && # 3 PostgreSQL + 3 MySQL
    [[ "$(fresh_count 'mysql_up{namespace="relational"}')" -ge 3 ]] &&
    [[ "$(down_count)" -eq 0 ]]
}

# Targets whose last scrape failed (empty result: none).
down_count() {
  local n
  n="$(k get --raw "/api/v1/namespaces/monitoring/services/kube-prometheus-stack-prometheus:http-web/proxy/api/v1/query?query=$(printf %s 'count(up == 0)' | jq -sRr @uri)" |
    grep -oE '"[0-9]+"\]' | tr -dc '0-9')"
  echo "${n:-0}"
}

if ! docker info >/dev/null 2>&1; then
  echo "Starting Docker Desktop"
  open -a Docker
fi
wait_for "Docker Desktop" 180 docker info || exit 1

# T0: only status written after this time counts. If every node container
# was already running, nothing restarts, so any status will do.
T0="1970-01-01T00:00:00Z"
if [[ "$(docker ps --filter "name=^$CLUSTER-" --format '{{.Names}}' | wc -l | tr -d ' ')" != 4 ]]; then
  T0="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi
docker start "$CLUSTER-control-plane" >/dev/null
docker start "$CLUSTER-worker" "$CLUSTER-worker2" "$CLUSTER-worker3" >/dev/null
wait_for "Kubernetes API" 120 k get --raw /readyz || exit 1
wait_for "Nodes reporting Ready since the restart" 180 nodes_fresh || exit 1
wait_for "Every pod restarted and ready" 600 pods_fresh

# Keep going if one is slow, so the checks show what is wrong.
wait_for "Galera: 3 members, all Synced" 600 galera_whole
wait_for "PXC operator: cluster ready, 3 nodes" 300 pxc_ready
wait_for "PostgreSQL: 2 replicas streaming" 300 pg_streaming
wait_for "Prometheus scraping the databases" 180 scraped

echo
"$DIR/platform/scripts/check_resources.sh"
echo
"$DIR/relational/scripts/check_resources.sh"
