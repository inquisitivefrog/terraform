#!/bin/bash
export AWS_PROFILE=blue-elephant # account 650836812595 (Free plan, us-east-2 only)
set -e

# Configuration
REGION="us-east-2"
CLUSTER_NAME="ecommerce-cluster"
VPC_NAME="ecommerce-vpc"
STATE_BUCKET="blue-elephant-ecommerce-terraform-state"
APP_BUCKET="blue-elephant-ecommerce-app-us-east-2-prod"
roles=("ecommerce-cluster-cluster-role" "ecommerce-cluster-node-role" "terraform-admin" "ecommerce-cluster-alb-controller")

echo "Checking for existing resources..."
for role in "${roles[@]}"; do
  if aws iam get-role --role-name "$role" >/dev/null 2>&1; then
    echo "Error: IAM role $role still exists, run cleanup script first"
    exit 1
  fi
done
if aws s3api head-bucket --bucket "$STATE_BUCKET" --region "$REGION" >/dev/null 2>&1; then
  echo "Error: S3 bucket $STATE_BUCKET still exists, run cleanup script first"
  exit 1
fi
if aws s3api head-bucket --bucket "$APP_BUCKET" --region "$REGION" >/dev/null 2>&1; then
  echo "Error: S3 bucket $APP_BUCKET still exists, run cleanup script first"
  exit 1
fi
vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query 'Vpcs[0].VpcId' --output text --region "$REGION" 2>/dev/null || echo "")
if [ -n "$vpc_id" ] && [ "$vpc_id" != "none" ]; then
  echo "Error: VPC $VPC_NAME ($vpc_id) still exists, run cleanup script first"
  exit 1
fi

echo "Start here"
cd /Users/tim/Documents/workspace/sre/terraform/aws/ecommerce-k8s

echo "Deploying Terraform state bucket..."
cd terraform-state
terraform init -reconfigure
terraform apply -auto-approve

echo "Deploying stage1-infra..."
cd ../stage1-infra
terraform init -backend-config=backend.hcl -reconfigure
terraform apply -auto-approve

echo "Deploying stage2-k8s..."
cd ../stage2-k8s
terraform init -backend-config=backend.hcl -reconfigure

# aws-auth needs no import: stage2 patches it (kubernetes_config_map_v1_data).

# Retry Terraform apply up to 3 times for stage2-k8s
max_attempts=3
attempt=1
while [ $attempt -le $max_attempts ]; do
  echo "Attempt $attempt of $max_attempts for stage2-k8s Terraform apply..."
  if terraform apply -auto-approve; then
    echo "stage2-k8s Terraform apply succeeded"
    break
  else
    echo "stage2-k8s Terraform apply failed, retrying after 30 seconds..."
    sleep 30
    attempt=$((attempt + 1))
  fi
done
if [ $attempt -gt $max_attempts ]; then
  echo "Error: stage2-k8s Terraform apply failed after $max_attempts attempts"
  exit 1
fi

echo "Waiting for EKS cluster to be active..."
aws eks wait cluster-active --name ecommerce-cluster --region us-east-2

echo "Updating kubeconfig..."
aws eks update-kubeconfig --name ecommerce-cluster --region us-east-2

echo "Checking AWS Load Balancer Controller logs..."
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --all-containers

echo "ArgoCD and ecommerce-app deployed via Terraform."
