#!/bin/bash

# Full cleanup script for tfstate and single_instance projects
# Run from /Users/tim/Documents/workspace/sre/terraform/aws/

# Check if script is run from the correct directory
EXPECTED_DIR="/Users/tim/Documents/workspace/sre/terraform/aws"
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "$EXPECTED_DIR" ]; then
  echo "Error: This script must be run from $EXPECTED_DIR"
  echo "Current directory is $CURRENT_DIR"
  echo "Please cd to $EXPECTED_DIR and try again."
  exit 1
fi

# Function to destroy Terraform Kubernetes resources
destroy_k8s() {
  local dir=$1
  echo "Destroying resources in $dir..."
  cd "$dir" || { echo "Failed to cd into $dir"; return 1; }
  terraform init -backend-config=backend.hcl >/dev/null 2>&1 || terraform init >/dev/null 2>&1 || echo "Terraform init failed in $dir (continuing anyway)"
  for resource in `terraform state list | grep kubernetes_deployment`
  do
      terraform state rm '$resource' >/dev/null 2>&1
  done
  for resource in `terraform state list | grep kubernetes_namespace`
  do
      terraform state rm '$resource' >/dev/null 2>&1
  done
  for resource in `terraform state list | grep kubernetes_resource_quota`
  do
      terraform state rm '$resource' >/dev/null 2>&1
  done
  for resource in `terraform state list | grep kubernetes_config_map`
  do
      terraform state rm '$resource' >/dev/null 2>&1
  done
  for resource in `terraform state list | grep kubernetes_secret`
  do
      terraform state rm '$resource' >/dev/null 2>&1
  done
  for resource in `terraform state list | grep kubernetes_role_binding`
  do
      terraform state rm '$resource' >/dev/null 2>&1
  done
  for resource in `terraform state list | grep kubernetes_role`
  do
      terraform state rm '$resource' >/dev/null 2>&1
  done
  cd - >/dev/null || exit 1
}

# Function to destroy Terraform resources
destroy_tf() {
  local dir=$1
  echo "Destroying resources in $dir..."
  cd "$dir" || { echo "Failed to cd into $dir"; return 1; }
  terraform init -backend-config=backend.hcl >/dev/null 2>&1 || terraform init >/dev/null 2>&1 || echo "Terraform init failed in $dir (continuing anyway)"
  terraform destroy -auto-approve || echo "Terraform destroy failed in $dir (continuing anyway)"
  cd - >/dev/null || exit 1
}

# Function to wipe S3 buckets
wipe_bucket() {
  local bucket=$1
  echo "Wiping bucket: $bucket"
  if aws s3 rb "s3://$bucket" --force >/dev/null 2>&1; then
    echo "Deleted $bucket"
  else
    echo "Force delete failed for $bucket, attempting manual cleanup..."
    aws s3api list-object-versions --bucket "$bucket" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json > /tmp/objects.json 2>/dev/null
    if [ -s /tmp/objects.json ] && [ "$(cat /tmp/objects.json)" != "null" ] && [ "$(cat /tmp/objects.json)" != "[]" ]; then
      aws s3api delete-objects --bucket "$bucket" --delete file:///tmp/objects.json >/dev/null 2>&1 || echo "Warning: Failed to delete objects in $bucket"
    fi
    aws s3api list-object-versions --bucket "$bucket" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json > /tmp/markers.json 2>/dev/null
    if [ -s /tmp/markers.json ] && [ "$(cat /tmp/markers.json)" != "null" ] && [ "$(cat /tmp/markers.json)" != "[]" ]; then
      aws s3api delete-objects --bucket "$bucket" --delete file:///tmp/markers.json >/dev/null 2>&1 || echo "Warning: Failed to delete markers in $bucket"
    fi
    if aws s3 rb "s3://$bucket" --force >/dev/null 2>&1; then
      echo "Deleted $bucket after manual cleanup"
    else
      echo "Failed to delete $bucket"
    fi
  fi
}

# Main cleanup
echo "Starting full cleanup..."

# Destroy single_instance environments first (depends on tfstate buckets)
destroy_k8s "single_instance/environments/dev"
destroy_k8s "single_instance/environments/prod"
destroy_tf "single_instance/environments/dev"
destroy_tf "single_instance/environments/prod"

# Destroy tfstate environments
destroy_tf "tfstate/environments/dev"
destroy_tf "tfstate/environments/prod"
destroy_tf "tfstate/bootstrap/dev"
destroy_tf "tfstate/bootstrap/prod"

# Wipe remaining S3 buckets
echo "Starting S3 bucket cleanup..."
BUCKETS=$(aws s3 ls | grep "bluedragon-" | awk '{print $3}' || true)
if [ -z "$BUCKETS" ]; then
  echo "No matching buckets found."
else
  for bucket in $BUCKETS; do
    wipe_bucket "$bucket"
  done
fi

rm -f /tmp/objects.json /tmp/markers.json
echo "Full cleanup complete!"
