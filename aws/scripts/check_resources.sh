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

ACCOUNT_ID="084375569056" # this repo's account; never grid-meter's
declare -A REGIONS=([dev]=us-west-2 [prod]=us-west-1)
R="${REGIONS[$env]}"
AWS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUCKET="bluedragon-tfstate-admin-$env"

PASS=0
FAIL=0

# expect <label> <wanted> <command...>: PASS only if stdout equals <wanted>
# ("" never counts: the CLI prints nothing, or "None", for a missing resource).
expect() {
  local label="$1" want="$2" out
  shift 2
  out="$("$@" 2>/dev/null)"
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

account="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)"
if [[ "$account" != "$ACCOUNT_ID" ]]; then
  echo "Logged in to account '${account:-none}', expected $ACCOUNT_ID. Stopping." >&2
  exit 1
fi
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
    check "single_instance state object" aws s3api head-object --bucket "$BUCKET" --key single_instance/terraform.tfstate --query LastModified --output text
  fi
fi

echo
CLUSTER="$(tf_output eks_cluster_name)"
if [[ -z "$CLUSTER" ]] || ! aws eks describe-cluster --region "$R" --name "$CLUSTER" >/dev/null 2>&1; then
  echo "-- single_instance: not applied; skipped --"
else
  SUFFIX="${CLUSTER##*-}"
  echo "-- single_instance (suffix $SUFFIX) --"

  # Network
  check "VPC (non-default)" aws ec2 describe-vpcs --region "$R" --filters Name=is-default,Values=false --query 'Vpcs[].VpcId' --output text
  check "NAT gateway available" aws ec2 describe-nat-gateways --region "$R" --filter Name=state,Values=available --query 'NatGateways[].NatGatewayId' --output text
  check "VPC flow log group KMS-encrypted" aws logs describe-log-groups --region "$R" --log-group-name-prefix /aws/vpc/flow-logs/ --query 'logGroups[0].kmsKeyId' --output text

  # EC2 (Project tag; AdminPolicy's ec2:* depends on it)
  check "EC2 running with Project tag" aws ec2 describe-instances --region "$R" \
    --filters Name=tag:Project,Values=bluedragon-single-instance Name=instance-state-name,Values=running --query 'Reservations[].Instances[].InstanceId' --output text
  expect "EC2 IMDSv1 disabled (count with optional tokens)" "0" aws ec2 describe-instances --region "$R" \
    --filters Name=tag:Project,Values=bluedragon-single-instance Name=instance-state-name,Values=running \
    --query "length(Reservations[].Instances[?MetadataOptions.HttpTokens!='required'][])" --output text
  check "SSH allowed from this laptop ($MY_IP/32)" aws ec2 describe-security-groups --region "$R" \
    --filters "Name=ip-permission.cidr,Values=$MY_IP/32" Name=ip-permission.from-port,Values=22 --query 'SecurityGroups[].GroupName' --output text

  # EKS
  expect "EKS cluster" "ACTIVE" aws eks describe-cluster --region "$R" --name "$CLUSTER" --query cluster.status --output text
  expect "EKS API allows this laptop" "$MY_IP/32" aws eks describe-cluster --region "$R" --name "$CLUSTER" \
    --query "cluster.resourcesVpcConfig.publicAccessCidrs[?@=='$MY_IP/32'] | [0]" --output text
  expect "EKS secrets encrypted with KMS" "secrets" aws eks describe-cluster --region "$R" --name "$CLUSTER" \
    --query 'cluster.encryptionConfig[0].resources[0]' --output text
  expect "EKS node group" "ACTIVE" aws eks describe-nodegroup --region "$R" --cluster-name "$CLUSTER" --nodegroup-name "ng-$env-$SUFFIX" \
    --query nodegroup.status --output text

  # Redis: TLS and AUTH (group 1, 2026-10-21)
  expect "Redis replication group" "available" aws elasticache describe-replication-groups --region "$R" --replication-group-id redis-single-instance \
    --query 'ReplicationGroups[0].Status' --output text
  expect "Redis TLS, at-rest encryption, AUTH" "True True True" aws elasticache describe-replication-groups --region "$R" \
    --replication-group-id redis-single-instance \
    --query 'ReplicationGroups[0].[TransitEncryptionEnabled,AtRestEncryptionEnabled,AuthTokenEnabled]' --output text

  # Storage, messaging, IAM
  expect "Dev bucket versioning" "Enabled" aws s3api get-bucket-versioning --bucket "bluedragon-dev-bucket-$SUFFIX" --query Status --output text
  check "SNS topics" aws sns list-topics --region "$R" --query "Topics[?contains(TopicArn, 'example-topic') || contains(TopicArn, 'custom-topic')].TopicArn" --output text
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
