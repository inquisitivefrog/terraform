#!/usr/bin/env bash
# Point kubectl at the ecommerce-k8s EKS cluster and show its health.
# Usage: aws/ecommerce-k8s/scripts/kube_use.sh      (run from anywhere)
# Context: ecommerce-cluster, in account 650836812595 via profile
# blue-elephant. Other contexts (grid-meter, eks-multi, eks-prod) are left
# alone; only the current context changes. Counterpart of aws/scripts/kube_use.sh.

set -euo pipefail
source "$(dirname "$0")/../../scripts/aws_env.sh" # ACCOUNT_ID, AWS_PROFILE, require_account
CLUSTER="ecommerce-cluster"
REGION="us-east-2"

require_account
if ! aws eks describe-cluster --region "$REGION" --name "$CLUSTER" >/dev/null 2>&1; then
  echo "Cluster $CLUSTER not found: apply stage1-infra first." >&2
  exit 1
fi

# Writes/refreshes the context and makes it current.
cmd="aws eks update-kubeconfig --region $REGION --name $CLUSTER --alias $CLUSTER --profile $AWS_PROFILE"
echo "+ $cmd"
eval "$cmd" >/dev/null

echo "Context: $(kubectl config current-context)"
echo
kubectl get nodes -o wide
echo
kubectl get pods -A
echo
kubectl get ingress -A
echo
kubectl get svc -A --field-selector spec.type=LoadBalancer
