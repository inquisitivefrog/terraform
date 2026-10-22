#!/usr/bin/env bash
# Point kubectl at a single_instance EKS cluster and show its health.
# Usage: ./kube_use.sh dev|prod      (run from anywhere)
# Contexts: dev = eks-multi, prod = eks-prod, both in account 650836812595
# via profile blue-elephant. The grid-meter context is left alone.

set -euo pipefail
source "$(dirname "$0")/aws_env.sh"

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
require_account

# Writes/refreshes the context and makes it current.
cmd=$(terraform output -raw kubeconfig_command)
echo "+ $cmd"
eval "$cmd" >/dev/null

echo "Context: $(kubectl config current-context)"
echo
kubectl get nodes -o wide
echo
kubectl get pods -A
