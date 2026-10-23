#!/usr/bin/env bash
# Show the Helm releases stage2-k8s installed on the ecommerce-k8s cluster:
# chart and app versions, status, and the values Terraform set.
# Usage: aws/ecommerce-k8s/scripts/helm_status.sh [release]   (read-only; run from anywhere)
#   no argument: every release, then a summary of each
#   release:     that release only, with its notes and resources
# Uses --kube-context ecommerce-cluster (kube_use.sh creates it), so the
# current context, grid-meter's included, is never used or changed.

set -euo pipefail
source "$(dirname "$0")/../../scripts/aws_env.sh" # ACCOUNT_ID, AWS_PROFILE, require_account
CTX="ecommerce-cluster"
# ecommerce-app is not a Helm release: Argo CD renders its chart from git and
# applies it (see argocd_use.sh). argocd-apps is the release that creates the
# Argo CD Application for it.
declare -A NAMESPACE=([aws-load-balancer-controller]=kube-system [argocd]=argocd [argocd-apps]=argocd)

require_account
if ! kubectl config get-contexts -o name | grep -x "$CTX" >/dev/null; then
  echo "No kubectl context $CTX: run aws/ecommerce-k8s/scripts/kube_use.sh first." >&2
  exit 1
fi
h() { helm --kube-context "$CTX" "$@"; }

release=${1:-}
if [[ -n "$release" ]]; then
  ns="${NAMESPACE[$release]:-}"
  [[ -n "$ns" ]] || { echo "Unknown release '$release' (expected: ${!NAMESPACE[*]})" >&2; exit 1; }
  echo "== helm status $release -n $ns"
  h status "$release" -n "$ns" --show-resources
  echo
  echo "== values set by Terraform (secrets redacted)"
  h get values "$release" -n "$ns" | sed -E 's/((secret|password|key)[A-Za-z]*: ).*/\1<redacted>/I'
  exit 0
fi

echo "== helm list (context $CTX)"
h list -A
echo
for release in "${!NAMESPACE[@]}"; do
  ns="${NAMESPACE[$release]}"
  echo "== $release ($ns)"
  h history "$release" -n "$ns" --max 3 2>/dev/null || echo "  not installed"
  echo
done
echo "Details for one release: $0 <release>"
echo "ecommerce-app is deployed by Argo CD, not Helm: see argocd_use.sh"
