#!/usr/bin/env bash
# Show the private cloud: nodes and their zones, the operators, the datastore
# clusters of every category, and which zone each datastore pod runs in.
# Prints the one line that points a shell at this cluster.
# Usage: private/datastore-clusters/platform/scripts/kube_use.sh [dev]   (read-only; run from anywhere)

set -euo pipefail
source "$(dirname "$0")/../../../scripts/private_env.sh" # use_cluster, k, CTX, KUBECONFIG
ENV="${1:-dev}"
SYSTEM='^(kube-system|kube-public|kube-node-lease|local-path-storage|default)$'
use_cluster "datastore-$ENV"

echo "Cluster: $CLUSTER   context: $CTX   kubeconfig: $KUBECONFIG"
echo "API:     $(k config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
echo
echo "== Nodes (each worker is one zone)"
k get nodes -L topology.kubernetes.io/region,topology.kubernetes.io/zone
echo
echo "== Helm releases (operators and shared services)"
if command -v helm >/dev/null; then helm --kube-context "$CTX" list -A; else echo "  helm not installed"; fi
echo

declare -A ZONE
while read -r node zone; do ZONE[$node]="$zone"; done < <(k get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.labels.topology\.kubernetes\.io/zone}{"\n"}{end}')

for ns in $(k get ns -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -vE "$SYSTEM"); do
  echo "== Namespace $ns: pods, node, zone"
  while read -r pod node phase; do
    [[ -n "$pod" ]] || continue
    printf '  %-34s %-10s %-24s %s\n' "$pod" "$phase" "$node" "${ZONE[$node]:-}"
  done < <(k get pods -n "$ns" -o jsonpath='{range .items[*]}{.metadata.name} {.spec.nodeName} {.status.phase}{"\n"}{end}')
  echo
done

echo "Use this cluster in the current shell only (other shells and ~/.kube/config are untouched):"
echo "  export KUBECONFIG=$KUBECONFIG"
