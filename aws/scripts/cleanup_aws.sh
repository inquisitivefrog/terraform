#!/bin/bash

#!/bin/bash

# Enhanced cleanup script for Terraform and AWS resources
# Run from /Users/tim/Documents/workspace/sre/terraform/aws/

EXPECTED_DIR="/Users/tim/Documents/workspace/sre/terraform/aws"
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "$EXPECTED_DIR" ]; then
  echo "Error: Must run from $EXPECTED_DIR"
  exit 1
fi

# Default region (override with environment variable if needed)
AWS_REGION=${AWS_REGION:-us-east-1}

# Function to destroy Terraform resources
destroy_tf() {
  local dir=$1
  echo "Destroying resources in $dir..."
  cd "$dir" || { echo "Failed to cd into $dir"; return 1; }
  terraform init -backend-config=backend.hcl >/dev/null 2>&1 || { echo "Terraform init failed in $dir"; return 1; }
  terraform plan -destroy -out=tfplan >/dev/null 2>&1 || { echo "Terraform plan failed in $dir"; return 1; }
  terraform apply -auto-approve tfplan || echo "Terraform destroy failed in $dir (check dependencies)"
  cd - >/dev/null || exit 1
}

# Function to wipe S3 buckets
wipe_bucket() {
  local bucket=$1
  echo "Wiping bucket: $bucket"
  aws s3api delete-objects --bucket "$bucket" --delete "$(aws s3api list-object-versions --bucket "$bucket" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" >/dev/null 2>&1
  aws s3api delete-objects --bucket "$bucket" --delete "$(aws s3api list-object-versions --bucket "$bucket" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')" >/dev/null 2>&1
  aws s3 rb "s3://$bucket" --force >/dev/null 2>&1 && echo "Deleted $bucket" || echo "Failed to delete $bucket"
}

# Function to audit and clean non-Terraform resources
clean_aws_resources() {
  echo "Auditing AWS resources in $AWS_REGION..."
  
  # VPCs
  VPCS=$(aws ec2 describe-vpcs --region "$AWS_REGION" --query 'Vpcs[*].VpcId' --output text)
  for vpc in $VPCS; do
    echo "Found VPC: $vpc (manual deletion required if not Terraform-managed)"
  done

  # EC2 Instances
  INSTANCES=$(aws ec2 describe-instances --region "$AWS_REGION" --query 'Reservations[*].Instances[*].InstanceId' --output text)
  for instance in $INSTANCES; do
    echo "Found EC2 instance: $instance"
    read -p "Delete instance $instance? (y/n): " confirm
    [ "$confirm" = "y" ] && aws ec2 terminate-instances --region "$AWS_REGION" --instance-ids "$instance"
  done

  # Elasticache
  CACHES=$(aws elasticache describe-cache-clusters --region "$AWS_REGION" --query 'CacheClusters[*].CacheClusterId' --output text)
  for cache in $CACHES; do
    echo "Found Elasticache cluster: $cache"
    read -p "Delete cluster $cache? (y/n): " confirm
    [ "$confirm" = "y" ] && aws elasticache delete-cache-cluster --region "$AWS_REGION" --cache-cluster-id "$cache"
  done

  # EKS Clusters
  EKS_CLUSTERS=$(aws eks list-clusters --region "$AWS_REGION" --query 'clusters[]' --output text)
  for cluster in $EKS_CLUSTERS; do
    echo "Found EKS cluster: $cluster"
    read -p "Delete cluster $cluster? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
      NODEGROUPS=$(aws eks list-nodegroups --cluster-name "$cluster" --region "$AWS_REGION" --query 'nodegroups[]' --output text)
      for ng in $NODEGROUPS; do
        aws eks delete-nodegroup --cluster-name "$cluster" --nodegroup-name "$ng" --region "$AWS_REGION"
      done
      aws eks delete-cluster --name "$cluster" --region "$AWS_REGION"
    fi
  done
}

# Main cleanup
echo "Starting full cleanup..."

# Destroy Terraform environments
for env in single_instance/environments/dev single_instance/environments/prod tfstate/environments/dev tfstate/environments/prod tfstate/bootstrap/dev tfstate/bootstrap/prod; do
  [ -d "$env" ] && destroy_tf "$env"
done

# Wipe all S3 buckets (not just bluedragon-)
echo "Starting S3 bucket cleanup..."
BUCKETS=$(aws s3 ls --region "$AWS_REGION" | awk '{print $3}')
for bucket in $BUCKETS; do
  wipe_bucket "$bucket"
done

# Audit and clean non-Terraform resources
clean_aws_resources

echo "Cleanup complete!"
