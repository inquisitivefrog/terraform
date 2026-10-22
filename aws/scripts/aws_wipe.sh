#!/usr/bin/env bash
# Tear down the tfstate layer so the AWS account stops costing money.
#
#   aws/scripts/aws_wipe.sh
#
# Order (each step's state lives in the next step's buckets):
#   1. tfstate/environments/{prod,dev}  KMS keys, SNS topic, suffixed buckets.
#                                       State: in the bootstrap bucket.
#   2. tfstate/bootstrap/{prod,dev}     bootstrap state and log buckets.
#                                       State: local terraform.tfstate.
#
# Refuses to start while single_instance (dev or prod) still has resources:
# destroy those first with terraform destroy in each environment directory.
#
# The state buckets are versioned with force_destroy = false, so before each
# terraform destroy the script empties that state's buckets (every object
# version and delete marker). S3 access logs can land after the emptying, so
# a failed destroy is retried after emptying again. Terraform does the
# deleting, so nothing it manages (KMS keys, SNS topics) is left orphaned.
#
# Safe to re-run after a partial failure. To rebuild later, follow the build
# order in aws/tfstate/docs/STATUS.md (bootstrap first).

set -euo pipefail

source "$(dirname "$0")/aws_env.sh" # ACCOUNT_ID, AWS_PROFILE, REGION, REGIONS, require_account
ENVS=(prod dev)
MAX_TRIES=5

AWS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

red() { printf '\033[31m%s\033[0m\n' "$*"; }
bold() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

bucket_exists() { aws s3api head-bucket --bucket "$1" >/dev/null 2>&1; }

# Names of the S3 buckets in the current directory's terraform state.
state_buckets() {
  terraform show -json |
    jq -r '[.. | objects | select(.mode? == "managed" and .type? == "aws_s3_bucket") | .values.bucket] | .[]'
}

# Delete every object version and delete marker, 1000 at a time.
empty_bucket() {
  local bucket=$1 region=$2 batch="$TMP/delete.json"
  bucket_exists "$bucket" || return 0
  while :; do
    aws s3api list-object-versions --bucket "$bucket" --region "$region" --max-items 1000 --output json |
      jq '{Objects: [(.Versions // [])[], (.DeleteMarkers // [])[] | {Key, VersionId}], Quiet: true}' >"$batch"
    [ "$(jq '.Objects | length' "$batch")" -eq 0 ] && break
    echo "  emptying $bucket: $(jq '.Objects | length' "$batch") object versions"
    aws s3api delete-objects --bucket "$bucket" --region "$region" --delete "file://$batch" >/dev/null
  done
}

# Empty this state's buckets, then terraform destroy; retry on late log objects.
destroy_dir() {
  local dir=$1 region=$2 buckets try
  bold "terraform destroy: $dir"
  cd "$AWS_DIR/$dir"
  if [ -f backend.hcl ]; then
    terraform init -input=false -reconfigure -backend-config=backend.hcl >/dev/null
  else
    terraform init -input=false >/dev/null
  fi
  if [ -z "$(terraform state list)" ]; then
    echo "  state is empty; nothing to destroy"
    return 0
  fi
  buckets=$(state_buckets)
  for try in $(seq 1 "$MAX_TRIES"); do
    for b in $buckets; do empty_bucket "$b" "$region"; done
    if terraform destroy -auto-approve -input=false; then
      return 0
    fi
    [ "$try" -lt "$MAX_TRIES" ] || break
    red "  destroy failed (attempt $try of $MAX_TRIES); emptying again in 30s"
    sleep 30
  done
  red "terraform destroy failed in $dir. Fix the error above and re-run."
  exit 1
}

# Abort if single_instance still has resources in either environment.
check_single_instance_empty() {
  local env count
  for env in "${ENVS[@]}"; do
    if ! bucket_exists "blue-elephant-tfstate-admin-$env"; then
      continue # bootstrap already gone, so single_instance state is too
    fi
    cd "$AWS_DIR/single_instance/environments/$env"
    terraform init -input=false -reconfigure -backend-config=backend.hcl >/dev/null
    count=$(terraform state list | wc -l | tr -d ' ')
    if [ "$count" -ne 0 ]; then
      red "single_instance/environments/$env still has $count resources."
      echo "Destroy it first:  cd single_instance/environments/$env && terraform destroy"
      exit 1
    fi
    echo "  single_instance/$env: state empty"
  done
}

# Anything billable left in the account's regions.
verify_cleanup() {
  local region key leftover=0
  bold "Checking for leftover resources"
  check() { # description, output of a list command
    if [ -n "$2" ] && [ "$2" != "None" ]; then
      red "  $1: $2"
      leftover=1
    fi
  }
  for region in "${REGIONS[@]}"; do
    echo "  $region"
    check "EKS clusters" "$(aws eks list-clusters --region "$region" --query 'clusters' --output text)"
    check "EC2 instances" "$(aws ec2 describe-instances --region "$region" --filters Name=instance-state-name,Values=pending,running,stopping,stopped --query 'Reservations[].Instances[].InstanceId' --output text)"
    check "NAT gateways" "$(aws ec2 describe-nat-gateways --region "$region" --filter Name=state,Values=pending,available --query 'NatGateways[].NatGatewayId' --output text)"
    check "Elastic IPs" "$(aws ec2 describe-addresses --region "$region" --query 'Addresses[].PublicIp' --output text)"
    check "Load balancers" "$(aws elbv2 describe-load-balancers --region "$region" --query 'LoadBalancers[].LoadBalancerName' --output text)"
    check "ElastiCache clusters" "$(aws elasticache describe-cache-clusters --region "$region" --query 'CacheClusters[].CacheClusterId' --output text)"
    check "Non-default VPCs" "$(aws ec2 describe-vpcs --region "$region" --filters Name=is-default,Values=false --query 'Vpcs[].VpcId' --output text)"
    for key in $(aws kms list-keys --region "$region" --query 'Keys[].KeyId' --output text); do
      if [ "$(aws kms describe-key --region "$region" --key-id "$key" \
        --query 'join(`/`, [KeyMetadata.KeyManager, KeyMetadata.KeyState])' --output text 2>/dev/null)" = "CUSTOMER/Enabled" ]; then
        check "Enabled customer KMS key" "$key"
      fi
    done
  done
  check "blue-elephant buckets" "$(aws s3api list-buckets --query 'Buckets[?starts_with(Name, `blue-elephant-`)].Name' --output text)"
  if [ "$leftover" -eq 0 ]; then
    echo "  nothing billable left from this repo (KMS keys pending deletion are free)"
  fi
}

# --- main -------------------------------------------------------------------

for cmd in aws terraform jq; do
  command -v "$cmd" >/dev/null || { red "$cmd is not installed"; exit 1; }
done

require_account

bold "Preflight"
check_single_instance_empty

cat <<EOF

This permanently deletes the tfstate layer in account $ACCOUNT_ID:
  - tfstate/environments/{prod,dev}: KMS keys, SNS topics, suffixed buckets
  - tfstate/bootstrap/{prod,dev}:    blue-elephant-tfstate-admin-{prod,dev}[-logs]
    including every state file and access log stored in them.
Other buckets (grid-meter etc.) are not touched.
EOF
read -r -p "Type 'wipe' to continue: " answer
[ "$answer" = "wipe" ] || { echo "Cancelled."; exit 1; }

for env in "${ENVS[@]}"; do
  if bucket_exists "blue-elephant-tfstate-admin-$env"; then
    destroy_dir "tfstate/environments/$env" "${REGION[$env]}"
  else
    echo "tfstate/environments/$env: bootstrap bucket already gone; skipping"
  fi
done

for env in "${ENVS[@]}"; do
  destroy_dir "tfstate/bootstrap/$env" "${REGION[$env]}"
done

verify_cleanup
bold "Done"
