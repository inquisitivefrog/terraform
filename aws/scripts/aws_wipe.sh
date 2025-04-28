#!/bin/bash

# Full cleanup script for tfstate and single_instance projects
# Run from /Users/tim/Documents/workspace/sre/terraform/aws/

EXPECTED_DIR="/Users/tim/Documents/workspace/sre/terraform/aws"
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "$EXPECTED_DIR" ]; then
  echo "Error: This script must be run from $EXPECTED_DIR"
  exit 1
fi

VERBOSE=${VERBOSE:-false}

# Validate AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Error: Invalid or missing AWS credentials"
  exit 1
fi

# Function to destroy Terraform Kubernetes resources
destroy_k8s() {
  local dir=$1
  echo "Destroying Kubernetes resources in $dir..."
  cd "$dir" || { echo "Failed to cd into $dir"; return 1; }
  if [ ! -f "main.tf" ] && [ ! -f "backend.hcl" ]; then
    echo "Error: No Terraform configuration found in $dir"
    return 1
  fi
  terraform init -backend-config=backend.hcl || terraform init || { echo "Terraform init failed in $dir"; return 1; }
  for resource in $(terraform state list | grep '^module.kubernetes_.*kubernetes_'); do
    terraform state rm "$resource" && echo "Removed $resource" || echo "Failed to remove $resource"
  done
  if terraform state list | grep -q '^module.kubernetes_.*kubernetes_'; then
    echo "Warning: Some Kubernetes resources still remain in $dir"
  else
    echo "All Kubernetes resources removed in $dir"
  fi
  cd - >/dev/null || exit 1
}

# Function to destroy Terraform resources
destroy_tf() {
  local dir=$1
  echo "Destroying resources in $dir..."
  cd "$dir" || { echo "Failed to cd into $dir"; return 1; }
  if [ ! -f "main.tf" ] && [ ! -f "backend.hcl" ]; then
    echo "Error: No Terraform configuration found in $dir"
    return 1
  fi
  if $VERBOSE; then
    terraform init -backend-config=backend.hcl || terraform init || { echo "Terraform init failed in $dir"; return 1; }
    terraform destroy -auto-approve || echo "Terraform destroy failed in $dir"
  else
    terraform init -backend-config=backend.hcl >/dev/null 2>&1 || terraform init >/dev/null 2>&1 || { echo "Terraform init failed in $dir"; return 1; }
    terraform destroy -auto-approve >/dev/null 2>&1 || echo "Terraform destroy failed in $dir"
  fi
  cd - >/dev/null || exit 1
}

# Function to wipe S3 buckets
wipe_bucket() {
  local bucket=$1
  echo "Wiping bucket: $bucket"
  if ! aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
    echo "Bucket $bucket does not exist or is inaccessible"
    return 1
  fi
  # Skip if Terraform state is still active
  if terraform state list >/dev/null 2>&1; then
    echo "Warning: Terraform state still active in current directory; skipping $bucket"
    return 1
  fi
  aws s3 cp "s3://$bucket/terraform.tfstate" "/tmp/$bucket-tfstate-backup-$(date +%s)" || echo "Warning: Failed to back up state file from $bucket"
  if aws s3 rb "s3://$bucket" --force; then
    echo "Deleted $bucket"
  else
    echo "Force delete failed for $bucket, attempting manual cleanup..."
    aws s3api list-object-versions --bucket "$bucket" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json > /tmp/objects.json
    if [ -s /tmp/objects.json ] && [ "$(cat /tmp/objects.json)" != "null" ] && [ "$(cat /tmp/objects.json)" != "[]" ]; then
      aws s3api delete-objects --bucket "$bucket" --delete file:///tmp/objects.json || echo "Warning: Failed to delete objects in $bucket"
    fi
    aws s3api list-object-versions --bucket "$bucket" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json > /tmp/markers.json
    if [ -s /tmp/markers.json ] && [ "$(cat /tmp/markers.json)" != "null" ] && [ "$(cat /tmp/markers.json)" != "[]" ]; then
      aws s3api delete-objects --bucket "$bucket" --delete file:///tmp/markers.json || echo "Warning: Failed to delete markers in $bucket"
    fi
    if aws s3 rb "s3://$bucket" --force; then
      echo "Deleted $bucket after manual cleanup"
    else
      echo "Failed to delete $bucket"
    fi
  fi
}

verify_cleanup() {
  echo "Verifying no residual AWS resources..."
  aws eks list-clusters --region us-west-2 --query 'clusters' --output text | grep -q . && echo "Warning: EKS clusters remain" || echo "No EKS clusters"
  aws s3api list-buckets --query 'Buckets[].Name' --output text | grep -q . && echo "Warning: Buckets remain" || echo "No buckets"
  aws ec2 describe-network-interfaces --region us-west-2 --query 'NetworkInterfaces[].NetworkInterfaceId' --output text | grep -q . && echo "Warning: ENIs remain" || echo "No ENIs"
  aws ec2 describe-vpcs --region us-west-2 --query 'Vpcs[].VpcId' --output text | grep -q . && echo "Warning: VPCs remain" || echo "No VPCs"
  aws ec2 describe-security-groups --region us-west-2 --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | grep -q . && echo "Warning: Custom security groups remain" || echo "No custom security groups"
  aws logs describe-log-groups --region us-west-2 --query 'logGroups[].logGroupName' --output text | grep -q . && echo "Warning: Log groups remain" || echo "No log groups"
  aws iam list-roles --query 'Roles[?RoleName==`EC2` || RoleName==`ECS` || starts_with(RoleName, `default-eks`) || starts_with(RoleName, `my-eks`)]' --output text | grep -q . && echo "Warning: Custom IAM roles remain" || echo "No custom IAM roles"
  aws kms list-keys --region us-west-2 --query 'Keys[?KeyState==`Enabled` && KeyManager==`CUSTOMER`].KeyId' --output text | grep -q . && echo "Warning: Billable KMS CMKs remain" || echo "No billable KMS CMKs"
}

# Main cleanup
echo "Starting full cleanup..."

# Define directories
DIRS=(
  "single_instance/environments/dev"
  "single_instance/environments/prod"
  "tfstate/environments/dev"
  "tfstate/environments/prod"
  "tfstate/bootstrap/dev"
  "tfstate/bootstrap/prod"
)

# Destroy resources
for dir in "${DIRS[@]}"; do
  if [[ "$dir" == single_instance/* ]]; then
    destroy_k8s "$dir"
  fi
  destroy_tf "$dir"
done

# Wipe S3 buckets
echo "Starting S3 bucket cleanup..."
BUCKETS=$(aws s3api list-buckets --query 'Buckets[?starts_with(Name, `bluedragon-`)].Name' --output text || true)
if [ -z "$BUCKETS" ]; then
  echo "No matching buckets found."
else
  for bucket in $BUCKETS; do
    wipe_bucket "$bucket"
  done
fi

verify_cleanup

rm -f /tmp/objects.json /tmp/markers.json
echo "Full cleanup complete!"
