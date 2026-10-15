#!/bin/bash

# Enhanced cleanup script for Terraform and AWS resources
# Run from /Users/tim/Documents/workspace/sre/terraform/aws/
# Usage: ./cleanup_aws_2.sh [us-east-1|us-west-1|all]

EXPECTED_DIR="/Users/tim/Documents/workspace/sre/terraform/aws"
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "$EXPECTED_DIR" ]; then
  echo "Error: Must run from $EXPECTED_DIR"
  exit 1
fi

# Regions to clean (default to both if 'all' or no argument)
if [ "$1" = "all" ] || [ -z "$1" ]; then
  REGIONS=("us-east-1" "us-west-1")
else
  REGIONS=("$1")
fi

# Function to destroy Terraform resources
destroy_tf() {
  local dir=$1
  local region=$2
  echo "Destroying resources in $dir ($region)..."
  cd "$dir" || { echo "Failed to cd into $dir"; return 1; }
  terraform init -backend-config=backend.hcl >/dev/null 2>&1 || { echo "Terraform init failed in $dir"; return 1; }
  terraform plan -destroy -out=tfplan >/dev/null 2>&1 || { echo "Terraform plan failed in $dir"; return 1; }
  terraform apply -auto-approve tfplan || echo "Terraform destroy failed in $dir (check dependencies)"
  cd - >/dev/null || exit 1
}

# Function to wipe S3 buckets
wipe_bucket() {
  local bucket=$1
  local region=$2
  echo "Wiping bucket: $bucket ($region)"
  aws s3api delete-objects --bucket "$bucket" --region "$region" --delete "$(aws s3api list-object-versions --bucket "$bucket" --region "$region" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" >/dev/null 2>&1
  aws s3api delete-objects --bucket "$bucket" --region "$region" --delete "$(aws s3api list-object-versions --bucket "$bucket" --region "$region" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')" >/dev/null 2>&1
  aws s3 rb "s3://$bucket" --region "$region" --force >/dev/null 2>&1 && echo "Deleted $bucket" || echo "Failed to delete $bucket"
}

# Function to audit and clean non-Terraform resources
clean_aws_resources() {
  local region=$1
  echo "Auditing AWS resources in $region..."

  # VPCs
  VPCS=$(aws ec2 describe-vpcs --region "$region" --query 'Vpcs[*].VpcId' --output text)
  for vpc in $VPCS; do
    echo "Found VPC: $vpc"
    read -p "Delete VPC $vpc? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
      # Delete dependencies (subnets, IGWs, etc.)
      SUBNETS=$(aws ec2 describe-subnets --region "$region" --filters Name=vpc-id,Values="$vpc" --query 'Subnets[*].SubnetId' --output text)
      for subnet in $SUBNETS; do
        aws ec2 delete-subnet --region "$region" --subnet-id "$subnet"
      done
      IGWS=$(aws ec2 describe-internet-gateways --region "$region" --filters Name=attachment.vpc-id,Values="$vpc" --query 'InternetGateways[*].InternetGatewayId' --output text)
      for igw in $IGWS; do
        aws ec2 detach-internet-gateway --region "$region" --internet-gateway-id "$igw" --vpc-id "$vpc"
        aws ec2 delete-internet-gateway --region "$region" --internet-gateway-id "$igw"
      done
      aws ec2 delete-vpc --region "$region" --vpc-id "$vpc"
    fi
  done

  # EC2 Instances
  INSTANCES=$(aws ec2 describe-instances --region "$region" --query 'Reservations[*].Instances[*].InstanceId' --output text)
  for instance in $INSTANCES; do
    echo "Found EC2 instance: $instance"
    read -p "Delete instance $instance? (y/n): " confirm
    [ "$confirm" = "y" ] && aws ec2 terminate-instances --region "$region" --instance-ids "$instance"
  done

  # Elasticache
  CACHES=$(aws elasticache describe-cache-clusters --region "$region" --query 'CacheClusters[*].CacheClusterId' --output text)
  for cache in $CACHES; do
    echo "Found Elasticache cluster: $cache"
    read -p "Delete cluster $cache? (y/n): " confirm
    [ "$confirm" = "y" ] && aws elasticache delete-cache-cluster --region "$region" --cache-cluster-id "$cache"
  done

  # EKS Clusters
  EKS_CLUSTERS=$(aws eks list-clusters --region "$region" --query 'clusters[]' --output text)
  for cluster in $EKS_CLUSTERS; do
    echo "Found EKS cluster: $cluster"
    read -p "Delete cluster $cluster? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
      NODEGROUPS=$(aws eks list-nodegroups --cluster-name "$cluster" --region "$region" --query 'nodegroups[]' --output text)
      for ng in $NODEGROUPS; do
        aws eks delete-nodegroup --cluster-name "$cluster" --nodegroup-name "$ng" --region "$region"
        aws eks wait nodegroup-deleted --cluster-name "$cluster" --nodegroup-name "$ng" --region "$region"
      done
      aws eks delete-cluster --name "$cluster" --region "$region"
    fi
  done

  # CloudFormation Stacks
  STACKS=$(aws cloudformation list-stacks --region "$region" --query 'StackSummaries[?StackStatus!=`DELETE_COMPLETE`].StackName' --output text)
  for stack in $STACKS; do
    echo "Found CloudFormation stack: $stack"
    read -p "Delete stack $stack? (y/n): " confirm
    [ "$confirm" = "y" ] && aws cloudformation delete-stack --region "$region" --stack-name "$stack"
  done

  # IAM Roles (global, only run for us-east-1)
  if [ "$region" = "us-east-1" ]; then
    ROLES=$(aws iam list-roles --query 'Roles[?contains(RoleName,`bluedragon`) || contains(RoleName,`ALBControllerRole`) || contains(RoleName,`Admin`) || contains(RoleName,`Developer`) || contains(RoleName,`EC2Role`) || contains(RoleName,`ecsTaskExecutionRole`) || contains(RoleName,`eks-`) || contains(RoleName,`vpc-flow-logs-role`)].RoleName' --output text)
    for role in $ROLES; do
      echo "Found IAM role: $role"
      read -p "Delete role $role? (y/n): " confirm
      if [ "$confirm" = "y" ]; then
        # Detach policies
        POLICIES=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[*].PolicyArn' --output text)
        for policy in $POLICIES; do
          aws iam detach-role-policy --role-name "$role" --policy-arn "$policy"
        done
        INLINE_POLICIES=$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames[]' --output text)
        for inline_policy in $INLINE_POLICIES; do
          aws iam delete-role-policy --role-name "$role" --policy-name "$inline_policy"
        done
        # Delete role
        aws iam delete-role --role-name "$role" && echo "Deleted role $role" || echo "Failed to delete role $role"
      fi
    done
  fi
}

# Main cleanup
echo "Starting full cleanup..."

# Destroy Terraform environments for each region
for region in "${REGIONS[@]}"; do
  echo "Cleaning region: $region"
  export AWS_REGION=$region
  for env in ecommerce-k8s/stage1-infra ecommerce-k8s/stage2-k8s ecommerce-k8s/terraform-state; do
    [ -d "$env" ] && destroy_tf "$env" "$region"
  done
done

# Wipe S3 buckets (global, run once)
if [[ "${REGIONS[*]}" =~ "us-east-1" ]]; then
  echo "Starting S3 bucket cleanup..."
  BUCKETS=$(aws s3 ls | grep bluedragon | awk '{print $3}')
  for bucket in $BUCKETS; do
    # Never touch Terraform state buckets without explicit confirmation
    if [[ "$bucket" == *tfstate* ]]; then
      read -p "Bucket $bucket holds Terraform state. Delete it? (y/n): " confirm
      [ "$confirm" = "y" ] || { echo "Skipping $bucket"; continue; }
    fi
    wipe_bucket "$bucket" "us-east-1"
  done
fi

# Audit and clean non-Terraform resources
for region in "${REGIONS[@]}"; do
  clean_aws_resources "$region"
done

# Verify cleanup
echo "Verifying cleanup..."
for region in "${REGIONS[@]}"; do
  echo "Checking $region..."
  aws ec2 describe-vpcs --region "$region" --query 'Vpcs[*].VpcId' --output text | grep -q . && echo "VPCs remain in $region" || echo "No VPCs in $region"
  aws ec2 describe-instances --region "$region" --query 'Reservations[*].Instances[*].InstanceId' --output text | grep -q . && echo "EC2 instances remain in $region" || echo "No EC2 instances in $region"
  aws elasticache describe-cache-clusters --region "$region" --query 'CacheClusters[*].CacheClusterId' --output text | grep -q . && echo "Elasticache clusters remain in $region" || echo "No Elasticache clusters in $region"
  aws eks list-clusters --region "$region" --query 'clusters[]' --output text | grep -q . && echo "EKS clusters remain in $region" || echo "No EKS clusters in $region"
  aws cloudformation list-stacks --region "$region" --query 'StackSummaries[?StackStatus!=`DELETE_COMPLETE`].StackName' --output text | grep -q . && echo "CloudFormation stacks remain in $region" || echo "No CloudFormation stacks in $region"
done

# Check S3 buckets
aws s3 ls | grep bluedragon | grep -q . && echo "S3 buckets remain" || echo "No S3 buckets"

# Check IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName,`bluedragon`) || contains(RoleName,`ALBControllerRole`) || contains(RoleName,`Admin`) || contains(RoleName,`Developer`) || contains(RoleName,`EC2Role`) || contains(RoleName,`ecsTaskExecutionRole`) || contains(RoleName,`eks-`) || contains(RoleName,`vpc-flow-logs-role`)].RoleName' --output text | grep -q . && echo "IAM roles remain" || echo "No IAM roles"

echo "Cleanup complete!"
