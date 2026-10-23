#!/usr/bin/env bash
# Confirm ecommerce-k8s exists and works as intended, by asking AWS and the
# cluster rather than trusting "Apply complete". ecommerce-k8s counterpart of
# aws/scripts/check_resources.sh (same PASS/FAIL style and false-PASS guards).
# Usage: aws/ecommerce-k8s/scripts/check_resources.sh   (read-only; run from anywhere)
# Stages that aren't applied are skipped, not failed. kubectl uses a temporary
# kubeconfig, so ~/.kube/config and its current context are never touched.

set -uo pipefail

source "$(dirname "$0")/../../scripts/aws_env.sh" # ACCOUNT_ID, AWS_PROFILE, REGION, require_account
export AWS_REGION="us-east-2"
CLUSTER="ecommerce-cluster"
STATE_BUCKET="blue-elephant-ecommerce-terraform-state"
APP_BUCKET="blue-elephant-ecommerce-app-us-east-2-prod"

KC="$(mktemp)"
trap 'rm -f "$KC"' EXIT

PASS=0
FAIL=0

# expect <label> <wanted> <command...>: PASS only if stdout equals <wanted>
# ("" never counts: the CLI prints nothing, or "None", for a missing resource).
expect() {
  local label="$1" want="$2" out
  shift 2
  out="$("$@" 2>/dev/null)"
  out="${out//$'\t'/ }" # --output text separates list values with tabs
  if [[ -n "$out" && "$out" != "None" && "$out" == "$want" ]]; then
    echo "  PASS  $label: $out"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label: expected '$want', got '${out:-nothing}'"
    FAIL=$((FAIL + 1))
  fi
}

# check <label> <command...>: PASS on exit 0 with non-empty, non-null stdout
check() {
  local label="$1" out
  shift
  out="$("$@" 2>/dev/null)"
  if [[ $? -eq 0 && -n "$out" && "$out" != "None" && "$out" != "null" ]]; then
    echo "  PASS  $label: ${out//$'\n'/, }"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label: not found"
    FAIL=$((FAIL + 1))
  fi
}

k() { kubectl --kubeconfig "$KC" --request-timeout=15s "$@"; }

require_account
MY_IP="$(curl -4 -s --max-time 5 ifconfig.me)"

echo "== ecommerce-k8s ($AWS_REGION, account $ACCOUNT_ID) =="

echo
if ! aws s3api head-bucket --bucket "$STATE_BUCKET" >/dev/null 2>&1; then
  echo "-- terraform-state: $STATE_BUCKET not found (not applied); skipped --"
else
  echo "-- terraform-state ($STATE_BUCKET) --"
  expect "State bucket versioning" "Enabled" aws s3api get-bucket-versioning --bucket "$STATE_BUCKET" --query Status --output text
  expect "State bucket public access blocked" "True True True True" aws s3api get-public-access-block --bucket "$STATE_BUCKET" \
    --query 'PublicAccessBlockConfiguration.[BlockPublicAcls,IgnorePublicAcls,BlockPublicPolicy,RestrictPublicBuckets]' --output text
  expect "State bucket encrypted with the state CMK" "aws:kms alias/ecommerce-k8s-tfstate" sh -c "printf '%s ' \
    \$(aws s3api get-bucket-encryption --bucket '$STATE_BUCKET' \
      --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text); \
    aws kms list-aliases --key-id \$(aws s3api get-bucket-encryption --bucket '$STATE_BUCKET' \
      --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.KMSMasterKeyID' --output text) \
      --query 'Aliases[0].AliasName' --output text"
fi

echo
if ! aws eks describe-cluster --name "$CLUSTER" >/dev/null 2>&1; then
  echo "-- stage1-infra: cluster $CLUSTER not found (not applied); skipped --"
  echo "-- stage2-k8s: needs the cluster; skipped --"
else
  VPC="$(aws eks describe-cluster --name "$CLUSTER" --query cluster.resourcesVpcConfig.vpcId --output text)"
  echo "-- stage1-infra ($CLUSTER, $VPC) --"

  # Network
  check "NAT gateway available" aws ec2 describe-nat-gateways --filter Name=state,Values=available "Name=vpc-id,Values=$VPC" \
    --query 'NatGateways[].NatGatewayId' --output text
  check "Public subnets tagged for internet-facing ELBs" aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC" Name=tag:kubernetes.io/role/elb,Values=1 --query 'Subnets[].SubnetId' --output text
  expect "VPC flow log (rejected traffic)" "ACTIVE REJECT" aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$VPC" \
    --query 'FlowLogs[0].[FlowLogStatus,TrafficType]' --output text
  check "S3 gateway endpoint" aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC" \
    "Name=service-name,Values=com.amazonaws.$AWS_REGION.s3" --query 'VpcEndpoints[].VpcEndpointId' --output text

  # EKS
  expect "EKS cluster" "ACTIVE" aws eks describe-cluster --name "$CLUSTER" --query cluster.status --output text
  expect "EKS API allows only this laptop" "$MY_IP/32" aws eks describe-cluster --name "$CLUSTER" \
    --query 'cluster.resourcesVpcConfig.publicAccessCidrs' --output text
  expect "EKS secrets encrypted with alias/$CLUSTER" "$(aws kms describe-key --key-id "alias/$CLUSTER" --query KeyMetadata.Arn --output text 2>/dev/null)" \
    aws eks describe-cluster --name "$CLUSTER" --query 'cluster.encryptionConfig[0].provider.keyArn' --output text
  expect "EKS node group" "ACTIVE" aws eks describe-nodegroup --cluster-name "$CLUSTER" --nodegroup-name default \
    --query nodegroup.status --output text
  expect "EKS Pod Identity agent add-on" "ACTIVE" aws eks describe-addon --cluster-name "$CLUSTER" --addon-name eks-pod-identity-agent \
    --query addon.status --output text
  expect "Pod Identity for the load-balancer controller" "kube-system aws-load-balancer-controller" aws eks list-pod-identity-associations \
    --cluster-name "$CLUSTER" --query 'associations[?serviceAccount==`aws-load-balancer-controller`].[namespace,serviceAccount] | [0]' --output text
  for principal in "user/blue-elephant" "role/terraform-admin"; do
    expect "Access entry $principal: cluster admin" "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" \
      aws eks list-associated-access-policies --cluster-name "$CLUSTER" --principal-arn "arn:aws:iam::$ACCOUNT_ID:$principal" \
      --query 'associatedAccessPolicies[?ends_with(policyArn, `/AmazonEKSClusterAdminPolicy`)].policyArn | [0]' --output text
  done
  # Created by modules/eks so destroy removes it (EKS would otherwise make it).
  expect "Control-plane log group retention (days)" "7" aws logs describe-log-groups \
    --log-group-name-prefix "/aws/eks/$CLUSTER/cluster" --query 'logGroups[0].retentionInDays' --output text

  # S3
  expect "App bucket encrypted with alias/$CLUSTER" "aws:kms $(aws kms describe-key --key-id "alias/$CLUSTER" --query KeyMetadata.Arn --output text 2>/dev/null)" \
    aws s3api get-bucket-encryption --bucket "$APP_BUCKET" \
    --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.[SSEAlgorithm,KMSMasterKeyID]' --output text
  expect "App bucket versioning" "Enabled" aws s3api get-bucket-versioning --bucket "$APP_BUCKET" --query Status --output text
  expect "App bucket public access blocked" "True True True True" aws s3api get-public-access-block --bucket "$APP_BUCKET" \
    --query 'PublicAccessBlockConfiguration.[BlockPublicAcls,IgnorePublicAcls,BlockPublicPolicy,RestrictPublicBuckets]' --output text

  echo
  if ! aws eks update-kubeconfig --name "$CLUSTER" --kubeconfig "$KC" >/dev/null 2>&1 || ! k get ns >/dev/null 2>&1; then
    echo "  FAIL  kubectl can't reach the API (laptop IP $MY_IP not allowed?); stage2 not checked"
    FAIL=$((FAIL + 1))
  elif ! k get deploy -n kube-system aws-load-balancer-controller >/dev/null 2>&1; then
    echo "-- stage2-k8s: load-balancer controller not installed (not applied); skipped --"
  else
    echo "-- stage2-k8s --"

    # Nodes and pods: "N of N" with N > 0, so an empty cluster can't pass.
    read -r NODES READY < <(k get nodes --no-headers 2>/dev/null |
      awk '{n++; if ($2 == "Ready") r++} END {print n+0, r+0}')
    expect "Nodes Ready" "$([[ ${NODES:-0} -gt 0 ]] && echo "$NODES of $NODES" || echo "at least one")" echo "${READY:-0} of ${NODES:-0}"
    read -r PODS RUNNING < <(k get pods -A --no-headers 2>/dev/null |
      awk '{n++; split($3, c, "/"); if ($4 == "Running" && c[1] == c[2]) r++} END {print n+0, r+0}')
    expect "Pods Running and ready" "$([[ ${PODS:-0} -gt 0 ]] && echo "$PODS of $PODS" || echo "at least one")" echo "${RUNNING:-0} of ${PODS:-0}"

    # Auth and RBAC
    check "aws-auth maps the node role" sh -c "kubectl --kubeconfig '$KC' get cm -n kube-system aws-auth -o jsonpath='{.data.mapRoles}' |
      grep -o 'role/ecommerce-cluster-node-role'"
    check "ClusterRoles" k get clusterroles blue-elephant-admin blue-elephant-impersonator terraform-admin -o name
    check "ClusterRoleBindings" k get clusterrolebindings blue-elephant-admin blue-elephant-impersonator terraform-admin -o name

    # Helm releases (Terraform's helm_release resources)
    expect "Load-balancer controller ready" "2/2" k get deploy -n kube-system aws-load-balancer-controller \
      -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
    check "Argo CD server ready" k get deploy -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].status.readyReplicas}'
    ARGO_HOST="$(k get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)"
    expect "Argo CD NLB active, internet-facing" "active internet-facing" aws elbv2 describe-load-balancers \
      --query "LoadBalancers[?DNSName=='${ARGO_HOST:-none}'].[State.Code,Scheme] | [0]" --output text
    expect "Argo CD UI answers through the NLB from this laptop" "200" curl -s -o /dev/null -m 10 -w '%{http_code}' "http://${ARGO_HOST:-none}/"

    # GitOps: Argo CD deploys the app from git (stage2's argocd-apps release).
    expect "Argo CD Application ecommerce-app" "Synced Healthy" k get applications.argoproj.io -n argocd ecommerce-app \
      -o jsonpath='{.status.sync.status} {.status.health.status}'
    REPO="$(k get applications.argoproj.io -n argocd ecommerce-app -o jsonpath='{.spec.source.repoURL} {.spec.source.targetRevision}' 2>/dev/null)"
    # shellcheck disable=SC2086 # REPO is "<url> <branch>", split on purpose
    expect "Argo CD deployed the latest commit of ${REPO:-its repo}" "$(git ls-remote ${REPO:-none} 2>/dev/null | cut -c1-12)" \
      sh -c "kubectl --kubeconfig '$KC' get applications.argoproj.io -n argocd ecommerce-app -o jsonpath='{.status.sync.revision}' | cut -c1-12"

    # Ingress -> ALB -> pods. The controller must not have hit IAM denials.
    HOST="$(k get ingress -n default ecommerce-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)"
    expect "Ingress has no AccessDenied events" "0" sh -c "kubectl --kubeconfig '$KC' get events -n default \
      --field-selector involvedObject.name=ecommerce-app -o jsonpath='{.items[*].message}' | grep -c AccessDenied"
    if [[ -z "$HOST" ]]; then
      echo "  FAIL  Ingress ecommerce-app: no load balancer hostname"
      FAIL=$((FAIL + 1))
    else
      expect "ALB active, internet-facing" "active internet-facing" aws elbv2 describe-load-balancers \
        --query "LoadBalancers[?DNSName=='$HOST'].[State.Code,Scheme] | [0]" --output text
      ALB_ARN="$(aws elbv2 describe-load-balancers --query "LoadBalancers[?DNSName=='$HOST'].LoadBalancerArn | [0]" --output text 2>/dev/null)"
      TG_ARN="$(aws elbv2 describe-target-groups --load-balancer-arn "$ALB_ARN" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)"
      expect "ALB targets healthy" "healthy" sh -c "aws elbv2 describe-target-health --target-group-arn '$TG_ARN' \
        --query 'TargetHealthDescriptions[].TargetHealth.State' --output text | tr '\t' '\n' | sort -u"
      expect "App answers through the ALB from this laptop" "200" curl -s -o /dev/null -m 10 -w '%{http_code}' "http://$HOST/"
    fi
  fi
fi

echo
echo "== Summary: $PASS passed, $FAIL failed =="
if [[ "$FAIL" -gt 0 ]]; then
  echo "One or more expected resources are missing or misconfigured."
  exit 1
fi
if [[ "$PASS" -eq 0 ]]; then
  echo "ecommerce-k8s is not applied; nothing to check."
else
  echo "All checked resources present and configured."
fi
