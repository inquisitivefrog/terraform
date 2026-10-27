#!/usr/bin/env bash
# Confirm the shared private-cloud platform (the kind cluster every datastore
# category runs on) exists and is configured as intended.
# Usage: private/datastore-clusters/platform/scripts/check_resources.sh [dev]   (read-only; run from anywhere)

set -uo pipefail
source "$(dirname "$0")/../../../scripts/private_env.sh" # use_cluster, k, CTX
source "$(dirname "$0")/../../../scripts/checks.sh"      # expect, match, summary
ENV="${1:-dev}"
ZONES="dc1-a dc1-b dc1-c"

scrape_targets() { echo "$(prom_count 'up==1') up, $(prom_count 'up==0') down"; }

# unlimited_containers <namespace>: running containers with no memory limit, or "all" (all have one)
unlimited_containers() {
  local out
  out="$(k -n "$1" get pods --field-selector=status.phase=Running \
    -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.name}={.resources.limits.memory}{"\n"}{end}{end}' |
    grep '=$' | cut -d= -f1 | sort -u | xargs)"
  echo "${out:-all}"
}

use_cluster "datastore-$ENV"
echo "== private/datastore-clusters platform $ENV (kind cluster $CLUSTER, context $CTX) =="
echo
expect "Nodes Ready" "4" sh -c "kubectl --context $CTX get nodes --no-headers | grep -cw Ready"
expect "One worker per zone" "$ZONES" sh -c "kubectl --context $CTX get nodes -l '!node-role.kubernetes.io/control-plane' \
  -o jsonpath='{range .items[*]}{.metadata.labels.topology\.kubernetes\.io/zone}{\"\n\"}{end}' | sort | tr '\n' ' ' | sed 's/ \$//'"
expect "Every node in region dc1" "dc1" sh -c "kubectl --context $CTX get nodes \
  -o jsonpath='{range .items[*]}{.metadata.labels.topology\.kubernetes\.io/region}{\"\n\"}{end}' | sort -u"
expect "Control plane takes no workloads" "NoSchedule" k get nodes -l node-role.kubernetes.io/control-plane \
  -o jsonpath='{.items[0].spec.taints[?(@.key=="node-role.kubernetes.io/control-plane")].effect}'
match "API server only on localhost" '^https://127\.0\.0\.1:[0-9]+$' k config view --minify -o jsonpath='{.clusters[0].cluster.server}'
expect "Default StorageClass (one volume per node, like local disk)" "standard rancher.io/local-path WaitForFirstConsumer" k get storageclass \
  -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name} {.provisioner} {.volumeBindingMode}{end}'

# Shared monitoring (environments/dev/services): skipped if not applied yet.
echo
if ! k get namespace monitoring >/dev/null 2>&1; then
  echo "-- monitoring: namespace monitoring not found (services not applied); skipped --"
else
  echo "-- monitoring (kube-prometheus-stack) --"
  expect "Prometheus ready" "1" k -n monitoring get statefulset prometheus-kube-prometheus-stack-prometheus -o jsonpath='{.status.readyReplicas}'
  expect "Alertmanager ready" "1" k -n monitoring get statefulset alertmanager-kube-prometheus-stack-alertmanager -o jsonpath='{.status.readyReplicas}'
  expect "Grafana available" "1" k -n monitoring get deployment kube-prometheus-stack-grafana -o jsonpath='{.status.availableReplicas}'
  expect "Remote-write receiver on (k6 results)" "true" k -n monitoring get prometheus kube-prometheus-stack-prometheus -o jsonpath='{.spec.enableRemoteWriteReceiver}'
  match "Scrape targets" '^[1-9][0-9]* up, 0 down$' scrape_targets
  match "Dashboards loaded by Grafana's sidecar" '^[1-9][0-9]*$' sh -c "kubectl --context $CTX get configmap -A -l grafana_dashboard=1 --no-headers | wc -l | tr -d ' '"
  # A container without a memory limit is unbounded on a node it shares with a database.
  expect "Every monitoring container has a memory limit" "all" unlimited_containers monitoring
fi
summary "platform resources"
