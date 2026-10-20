#!/usr/bin/env bash
# Point kubectl at a gcp/single_instance GKE cluster and show its health.
# Usage: ./kube_use.sh dev|prod      (run from anywhere)
# Writes ~/.kube/gcp-<env> only; ~/.kube/config (and the grid-meter
# contexts) is never touched. To keep using the cluster afterwards:
#   export KUBECONFIG=~/.kube/gcp-<env>

set -euo pipefail

env=${1:-}
case "$env" in
  dev | prod) ;;
  *)
    echo "Usage: $0 dev|prod" >&2
    exit 1
    ;;
esac

env_dir="$(cd "$(dirname "$0")/../single_instance/environments/$env" && pwd)"
cd "$env_dir"

export KUBECONFIG=~/.kube/gcp-$env

cmd=$(terraform output -raw kubeconfig_command) # includes --project
echo "+ KUBECONFIG=$KUBECONFIG $cmd"
eval "$cmd" >/dev/null 2>&1

echo "Context: $(kubectl config current-context)"
echo
kubectl get nodes -o wide
echo
kubectl get pods -A
echo
echo "To keep using it: export KUBECONFIG=$KUBECONFIG"
