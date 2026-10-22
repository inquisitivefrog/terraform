#!/usr/bin/env bash
# Confirm aws/tfstate and aws/single_instance resources exist and are
# configured as intended, by asking AWS rather than trusting "Apply complete".
# AWS counterpart of azure/scripts/check_resources.sh (same false-PASS guards).
# Usage: aws/scripts/check_resources.sh dev|prod      (read-only; run from anywhere)
# Sections that aren't applied are skipped, not failed.

set -uo pipefail

env=${1:-}
case "$env:$#" in
  dev:1 | prod:1) ;;
  *)
    echo "Usage: $0 dev|prod" >&2
    exit 1
    ;;
esac

source "$(dirname "$0")/aws_env.sh" # ACCOUNT_ID, AWS_PROFILE, REGION, REGIONS, require_account
R="${REGION[$env]}"
AWS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUCKET="blue-elephant-tfstate-admin-$env"

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

# terraform output -raw prints a multi-line warning on empty state
tf_output() {
  local val
  val="$(cd "$AWS_DIR/single_instance/environments/$env" && terraform output -raw "$1" 2>/dev/null)"
  [[ "$val" == *$'\n'* ]] && val=""
  printf '%s' "$val"
}

require_account
MY_IP="$(curl -4 -s --max-time 5 ifconfig.me)"

echo "== aws $env ($R, account $ACCOUNT_ID) =="

echo
if ! aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
  echo "-- tfstate/bootstrap: $BUCKET not found (not applied); skipped --"
else
  echo "-- tfstate/bootstrap ($BUCKET) --"
  expect "State bucket versioning" "Enabled" aws s3api get-bucket-versioning --bucket "$BUCKET" --query Status --output text
  expect "State bucket public access blocked" "True True True True" aws s3api get-public-access-block --bucket "$BUCKET" \
    --query 'PublicAccessBlockConfiguration.[BlockPublicAcls,IgnorePublicAcls,BlockPublicPolicy,RestrictPublicBuckets]' --output text
  check "State bucket encryption" aws s3api get-bucket-encryption --bucket "$BUCKET" \
    --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text
  expect "State bucket access logs" "$BUCKET-logs" aws s3api get-bucket-logging --bucket "$BUCKET" --query LoggingEnabled.TargetBucket --output text
  check "Log bucket" aws s3api head-bucket --bucket "$BUCKET-logs" --query 'BucketRegion' --output text

  echo
  key="$(aws kms describe-key --region "$R" --key-id "alias/tfstate-$env" --query KeyMetadata.KeyId --output text 2>/dev/null)"
  if [[ -z "$key" || "$key" == "None" ]]; then
    echo "-- tfstate/environments: alias/tfstate-$env not found (not applied); skipped --"
  else
    echo "-- tfstate/environments (alias/tfstate-$env) --"
    expect "State key enabled" "Enabled" aws kms describe-key --region "$R" --key-id "$key" --query KeyMetadata.KeyState --output text
    expect "State key rotation" "True" aws kms get-key-rotation-status --region "$R" --key-id "$key" --query KeyRotationEnabled --output text
  fi
fi

echo
CLUSTER="$(tf_output eks_cluster_name)"
if [[ -z "$CLUSTER" ]] || ! aws eks describe-cluster --region "$R" --name "$CLUSTER" >/dev/null 2>&1; then
  echo "-- single_instance: not applied; skipped --"
else
  # Cluster is eks-<tf env>-<suffix>; tf env is the env variable in tfvars
  # (dev uses "multi"). Dev and prod share us-east-2, so every check below is
  # pinned to this environment's VPC or names, never "any in the region".
  SUFFIX="${CLUSTER##*-}"
  TF_ENV="${CLUSTER#eks-}"
  TF_ENV="${TF_ENV%-*}"
  VPC="$(tf_output vpc_id)"
  echo "-- single_instance (env $TF_ENV, suffix $SUFFIX, ${VPC:-vpc_id output missing}) --"

  # State (backend.hcl: kms_key_id = alias/tfstate-<env>)
  expect "State object KMS-encrypted" "aws:kms" aws s3api head-object --bucket "$BUCKET" --key single_instance/terraform.tfstate \
    --query ServerSideEncryption --output text

  # Network
  check "VPC (non-default)" aws ec2 describe-vpcs --region "$R" --vpc-ids "$VPC" --filters Name=is-default,Values=false --query 'Vpcs[].VpcId' --output text
  check "NAT gateway available" aws ec2 describe-nat-gateways --region "$R" --filter Name=state,Values=available "Name=vpc-id,Values=$VPC" --query 'NatGateways[].NatGatewayId' --output text
  check "VPC flow log group KMS-encrypted" aws logs describe-log-groups --region "$R" --log-group-name-prefix "/aws/vpc/flow-logs/$VPC" --query 'logGroups[0].kmsKeyId' --output text

  # EC2 (Project tag; AdminPolicy's ec2:* depends on it)
  # Both instances (public + private). Count compliant instances rather than
  # non-compliant ones: "0 with optional tokens" also passes when none exist.
  expect "EC2 running with Project tag (public + private)" "2" aws ec2 describe-instances --region "$R" \
    --filters Name=tag:Project,Values=blue-elephant-single-instance Name=instance-state-name,Values=running "Name=vpc-id,Values=$VPC" \
    --query 'length(Reservations[].Instances[])' --output text
  expect "EC2 IMDSv2 required (instances with tokens required)" "2" aws ec2 describe-instances --region "$R" \
    --filters Name=tag:Project,Values=blue-elephant-single-instance Name=instance-state-name,Values=running "Name=vpc-id,Values=$VPC" \
    --query "length(Reservations[].Instances[?MetadataOptions.HttpTokens=='required'][])" --output text
  check "SSH allowed from this laptop ($MY_IP/32)" aws ec2 describe-security-groups --region "$R" \
    --filters "Name=ip-permission.cidr,Values=$MY_IP/32" Name=ip-permission.from-port,Values=22 "Name=vpc-id,Values=$VPC" --query 'SecurityGroups[].GroupName' --output text

  # EKS
  expect "EKS cluster" "ACTIVE" aws eks describe-cluster --region "$R" --name "$CLUSTER" --query cluster.status --output text
  expect "EKS API allows this laptop" "$MY_IP/32" aws eks describe-cluster --region "$R" --name "$CLUSTER" \
    --query "cluster.resourcesVpcConfig.publicAccessCidrs[?@=='$MY_IP/32'] | [0]" --output text
  expect "EKS secrets encrypted with KMS" "secrets" aws eks describe-cluster --region "$R" --name "$CLUSTER" \
    --query 'cluster.encryptionConfig[0].resources[0]' --output text
  expect "EKS node group" "ACTIVE" aws eks describe-nodegroup --region "$R" --cluster-name "$CLUSTER" --nodegroup-name "ng-$TF_ENV-$SUFFIX" \
    --query nodegroup.status --output text
  # Every node root volume encrypted; "N of N" with N > 0, so no nodes can't pass.
  read -r NVOL NENC < <(aws ec2 describe-volumes --region "$R" --filters "Name=tag:eks:nodegroup-name,Values=ng-$TF_ENV-$SUFFIX" \
    --query '[length(Volumes), length(Volumes[?Encrypted])]' --output text 2>/dev/null)
  expect "EKS node volumes encrypted" "$([[ ${NVOL:-0} -gt 0 ]] && echo "$NVOL of $NVOL" || echo "at least one")" echo "${NENC:-0} of ${NVOL:-0}"

  # Redis: TLS and AUTH (group 1, 2026-10-21)
  expect "Redis replication group" "available" aws elasticache describe-replication-groups --region "$R" --replication-group-id "redis-single-instance-$TF_ENV" \
    --query 'ReplicationGroups[0].Status' --output text
  expect "Redis TLS, at-rest encryption, AUTH" "True True True" aws elasticache describe-replication-groups --region "$R" \
    --replication-group-id "redis-single-instance-$TF_ENV" \
    --query 'ReplicationGroups[0].[TransitEncryptionEnabled,AtRestEncryptionEnabled,AuthTokenEnabled]' --output text

  # Storage, messaging, IAM
  expect "Dev bucket versioning" "Enabled" aws s3api get-bucket-versioning --bucket "blue-elephant-dev-bucket-$SUFFIX" --query Status --output text
  check "SNS topics" aws sns list-topics --region "$R" --query "Topics[?ends_with(TopicArn, ':example-topic-$TF_ENV') || ends_with(TopicArn, ':custom-topic-$TF_ENV.fifo')].TopicArn" --output text
  check "Shared IAM: DeveloperPolicy and AdminPolicy" aws iam list-policies --scope Local \
    --query "Policies[?PolicyName=='DeveloperPolicy' || PolicyName=='AdminPolicy'].PolicyName" --output text
fi

echo
echo "== Summary: $PASS passed, $FAIL failed =="
if [[ "$FAIL" -gt 0 ]]; then
  echo "One or more expected resources are missing or misconfigured."
  exit 1
fi
if [[ "$PASS" -eq 0 ]]; then
  echo "Nothing applied in $env; nothing to check."
else
  echo "All checked resources present and configured."
fi
