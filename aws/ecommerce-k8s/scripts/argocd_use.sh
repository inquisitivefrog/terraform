#!/usr/bin/env bash
# Show how to reach the ecommerce-k8s Argo CD: UI URL, admin login, health
# of its components, and its Applications.
# Usage: aws/ecommerce-k8s/scripts/argocd_use.sh [--login]   (run from anywhere)
#   --login  also log the argocd CLI in (brew install argocd), if installed
# The UI is plain HTTP (server runs --insecure) behind an NLB that only
# accepts this laptop's IP (loadBalancerSourceRanges = my_laptop_cidr_block).
# Uses --context ecommerce-cluster (kube_use.sh creates it), so the current
# context, grid-meter's included, is never used or changed.

set -euo pipefail
source "$(dirname "$0")/../../scripts/aws_env.sh" # ACCOUNT_ID, AWS_PROFILE, require_account
CTX="ecommerce-cluster"
NS="argocd"

require_account
if ! kubectl config get-contexts -o name | grep -x "$CTX" >/dev/null; then
  echo "No kubectl context $CTX: run aws/ecommerce-k8s/scripts/kube_use.sh first." >&2
  exit 1
fi
k() { kubectl --context "$CTX" -n "$NS" "$@"; }

if ! k get deploy -l app.kubernetes.io/name=argocd-server -o name 2>/dev/null | grep . >/dev/null; then
  echo "Argo CD is not installed: apply stage2-k8s first." >&2
  exit 1
fi

echo "== Argo CD components"
k get deploy,statefulset -o wide
echo

HOST="$(k get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
# Argo CD 2.x+ stores a generated password in this Secret; 1.x (chart 2.17.0,
# pinned in stage2) uses the argocd-server pod name instead.
if PASS="$(k get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)" && [[ -n "$PASS" ]]; then
  SOURCE="secret argocd-initial-admin-secret"
else
  PASS="$(k get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}')"
  SOURCE="argocd-server pod name (Argo CD 1.x default)"
fi
MY_IP="$(curl -4 -s --max-time 5 ifconfig.me || true)"
CODE="$(curl -s -o /dev/null -m 10 -w '%{http_code}' "http://$HOST/" || true)"

echo "== Login"
echo "  URL:      http://${HOST:-<NLB not ready>}/   (HTTP $CODE from $MY_IP)"
echo "  User:     admin"
echo "  Password: $PASS"
echo "            from the $SOURCE; change it after first login"
echo "  Version:  $(k get deploy -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].spec.template.spec.containers[0].image}')"
echo

echo "== Applications"
apps="$(k get applications.argoproj.io 2>/dev/null || true)"
echo "${apps:-  none: no Application resources yet (stage2 installs the app with Helm, not Argo CD)}"

if [[ "${1:-}" == "--login" ]]; then
  echo
  if command -v argocd >/dev/null 2>&1; then
    argocd login "$HOST" --username admin --password "$PASS" --plaintext --grpc-web
    argocd app list
  else
    echo "argocd CLI not installed (brew install argocd); the UI above works without it."
  fi
fi
