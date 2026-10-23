#!/bin/bash
export AWS_PROFILE=blue-elephant # account 650836812595 (Free plan, us-east-2 only)

# ecommerce-k8s-cleanup.sh
# Cleanup script for EKS cluster and related resources in us-east-2

# Configuration
REGION="us-east-2"
CLUSTER_NAME="ecommerce-cluster"
STATE_BUCKET="blue-elephant-ecommerce-terraform-state"
APP_BUCKET="blue-elephant-ecommerce-app-us-east-2-prod"
VPC_NAME="ecommerce-vpc"
LOG_FILE="/Users/tim/logs/ecommerce-cleanup-$(date +%Y%m%d-%H%M%S).log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log and execute commands
run_cmd() {
  echo "Running: $*" >> "$LOG_FILE"
  if "$@"; then
    echo "Success: $*" >> "$LOG_FILE"
  else
    echo "Error: Failed to execute $*" >> "$LOG_FILE"
    return 1
  fi
}

echo "Starting cleanup at $(date)" >> "$LOG_FILE"

# Navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || { echo "Failed to navigate to project root" >> "$LOG_FILE"; exit 1; }

# Update kubeconfig for EKS cluster if it exists
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "Updating kubeconfig for $CLUSTER_NAME..." >> "$LOG_FILE"
  run_cmd aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" || \
    echo "Failed to update kubeconfig, proceeding with cleanup" >> "$LOG_FILE"
else
  echo "EKS cluster $CLUSTER_NAME does not exist, skipping kubeconfig update" >> "$LOG_FILE"
fi

# Delete ArgoCD applications (if used)
echo "Checking for ArgoCD applications..." >> "$LOG_FILE"
if kubectl get namespace argocd >/dev/null 2>&1; then
  argocd_apps=$(kubectl get applications -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null || echo "")
  if [ -n "$argocd_apps" ]; then
    echo "$argocd_apps" | while read -r app; do
      echo "Deleting ArgoCD application $app..." >> "$LOG_FILE"
      run_cmd kubectl delete application "$app" -n argocd --timeout=600s || \
        echo "Failed to delete ArgoCD application $app, may be already deleted" >> "$LOG_FILE"
    done
  else
    echo "No ArgoCD applications found" >> "$LOG_FILE"
  fi
else
  echo "ArgoCD namespace not found, skipping ArgoCD cleanup" >> "$LOG_FILE"
fi

# Delete Helm releases
echo "Checking for Helm releases..." >> "$LOG_FILE"
if kubectl get namespaces >/dev/null 2>&1; then
  helm_releases=$(helm list --all-namespaces --output json | jq -r '.[] | .name + " " + .namespace' 2>/dev/null || echo "")
  if [ -n "$helm_releases" ]; then
    echo "$helm_releases" | while read -r release namespace; do
      echo "Deleting Helm release $release in namespace $namespace..." >> "$LOG_FILE"
      run_cmd helm uninstall "$release" --namespace "$namespace" --timeout=600s || \
        echo "Failed to delete Helm release $release in namespace $namespace" >> "$LOG_FILE"
    done
  else
    echo "No Helm releases found" >> "$LOG_FILE"
  fi
else
  echo "Kubernetes cluster unreachable, skipping Helm cleanup" >> "$LOG_FILE"
fi

# Delete Kubernetes Ingress resources (to trigger ALB cleanup)
echo "Deleting Ingress resources..." >> "$LOG_FILE"
if kubectl get namespaces >/dev/null 2>&1; then
  ingresses=$(kubectl get ingress --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.namespace}{"\n"}{end}' 2>/dev/null || echo "")
  if [ -n "$ingresses" ]; then
    echo "$ingresses" | while read -r ingress namespace; do
      echo "Deleting Ingress $ingress in namespace $namespace..." >> "$LOG_FILE"
      run_cmd kubectl delete ingress "$ingress" -n "$namespace" --timeout=600s || \
        echo "Failed to delete Ingress $ingress in namespace $namespace" >> "$LOG_FILE"
    done
  else
    echo "No Ingress resources found" >> "$LOG_FILE"
  fi
else
  echo "Kubernetes cluster unreachable, skipping Ingress cleanup" >> "$LOG_FILE"
fi

# Wait for ALB resources to be deleted
echo "Waiting for ALB resources to be deleted..." >> "$LOG_FILE"
max_attempts=20
attempt=1
while [ $attempt -le $max_attempts ]; do
  albs=$(aws elbv2 describe-load-balancers --region "$REGION" --query 'LoadBalancers[?contains(LoadBalancerName, `ecommerce-cluster`)].LoadBalancerArn' --output text 2>/dev/null || echo "")
  if [ -z "$albs" ]; then
    echo "No ALBs found, proceeding..." >> "$LOG_FILE"
    break
  fi
  echo "Found ALBs: $albs, waiting for deletion (attempt $attempt/$max_attempts)..." >> "$LOG_FILE"
  sleep 30
  attempt=$((attempt + 1))
done
if [ $attempt -gt $max_attempts ]; then
  echo "Error: ALBs still exist after $max_attempts attempts, manual cleanup may be required" >> "$LOG_FILE"
  exit 1
fi

# Delete lingering TargetGroups
echo "Deleting TargetGroups..." >> "$LOG_FILE"
target_groups=$(aws elbv2 describe-target-groups --region "$REGION" --query 'TargetGroups[?contains(TargetGroupName, `ecommerce-cluster`)].TargetGroupArn' --output text 2>/dev/null || echo "")
for tg in $target_groups; do
  echo "Deleting TargetGroup $tg..." >> "$LOG_FILE"
  run_cmd aws elbv2 delete-target-group --target-group-arn "$tg" --region "$REGION" || \
    echo "Failed to delete TargetGroup $tg, may be already deleted" >> "$LOG_FILE"
done

# Terraform destroy for stage2-k8s
echo "Destroying stage2-k8s resources..." >> "$LOG_FILE"
cd stage2-k8s
if aws s3api head-bucket --bucket "$STATE_BUCKET" --region "$REGION" >/dev/null 2>&1; then
  echo "Initializing Terraform with S3 backend ($STATE_BUCKET)..." >> "$LOG_FILE"
  if run_cmd terraform init -backend-config=backend.hcl -reconfigure >> "$LOG_FILE" 2>&1; then
    if [ -z "$(terraform state list)" ]; then
      echo "Terraform state for stage2-k8s is empty, skipping destroy" >> "$LOG_FILE"
    else
      # Remove aws-auth ConfigMap from state to avoid conflicts
      if terraform state list | grep kubernetes_config_map_v1_data.aws_auth >/dev/null; then
        echo "Removing aws-auth ConfigMap from Terraform state..." >> "$LOG_FILE"
        run_cmd terraform state rm kubernetes_config_map_v1_data.aws_auth || \
          echo "Failed to remove aws-auth ConfigMap from state" >> "$LOG_FILE"
      fi
      run_cmd terraform destroy -auto-approve || \
        echo "Terraform destroy failed in stage2-k8s, may be partially complete" >> "$LOG_FILE"
    fi
  else
    echo "Warning: Failed to initialize Terraform in stage2-k8s, state may be inaccessible" >> "$LOG_FILE"
  fi
else
  echo "Skipping stage2-k8s destroy, S3 bucket $STATE_BUCKET does not exist" >> "$LOG_FILE"
fi
cd ..

# Terraform destroy for stage1-infra
echo "Destroying stage1-infra resources..." >> "$LOG_FILE"
cd stage1-infra
if aws s3api head-bucket --bucket "$STATE_BUCKET" --region "$REGION" >/dev/null 2>&1; then
  echo "Initializing Terraform with S3 backend ($STATE_BUCKET)..." >> "$LOG_FILE"
  if run_cmd terraform init -backend-config=backend.hcl -reconfigure >> "$LOG_FILE" 2>&1; then
    if [ -z "$(terraform state list)" ]; then
      echo "Terraform state for stage1-infra is empty, skipping destroy" >> "$LOG_FILE"
    else
      run_cmd terraform destroy -auto-approve || \
        echo "Terraform destroy failed in stage1-infra, may be partially complete" >> "$LOG_FILE"
    fi
  else
    echo "Warning: Failed to initialize Terraform in stage1-infra, state may be inaccessible" >> "$LOG_FILE"
  fi
else
  echo "Skipping stage1-infra destroy, S3 bucket $STATE_BUCKET does not exist" >> "$LOG_FILE"
fi
cd ..

# Terraform destroy for terraform-state
echo "Destroying terraform-state resources..." >> "$LOG_FILE"
cd terraform-state
if aws s3api head-bucket --bucket "$STATE_BUCKET" --region "$REGION" >/dev/null 2>&1; then
  echo "Initializing Terraform with S3 backend ($STATE_BUCKET)..." >> "$LOG_FILE"
  if run_cmd terraform init -reconfigure >> "$LOG_FILE" 2>&1; then
    if [ -z "$(terraform state list)" ]; then
      echo "Terraform state for terraform-state is empty, skipping destroy" >> "$LOG_FILE"
    else
      run_cmd terraform destroy -auto-approve || \
        echo "Terraform destroy failed in terraform-state, may be partially complete" >> "$LOG_FILE"
    fi
  else
    echo "Warning: Failed to initialize Terraform in terraform-state, state may be inaccessible" >> "$LOG_FILE"
  fi
else
  echo "Skipping terraform-state destroy, S3 bucket $STATE_BUCKET does not exist" >> "$LOG_FILE"
fi
cd ..

# Delete lingering EKS resources
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "EKS cluster $CLUSTER_NAME exists, proceeding with cleanup" >> "$LOG_FILE"
  max_attempts=5
  attempt=1
  while [ $attempt -le $max_attempts ]; do
    echo "Attempt $attempt to delete EKS access entries" >> "$LOG_FILE"
    access_entries=$(aws eks list-access-entries --cluster-name "$CLUSTER_NAME" --query 'accessEntries[]' --output text --region "$REGION" 2>/dev/null || echo "")
    if [ -z "$access_entries" ]; then
      echo "No access entries found for cluster $CLUSTER_NAME" >> "$LOG_FILE"
      break
    fi
    entries_deleted=true
    echo "$access_entries" | while read -r access_entry; do
      if [ -n "$access_entry" ] && [[ ! "$access_entry" =~ aws-service-role/eks.amazonaws.com ]]; then
        echo "Deleting access entry: $access_entry" >> "$LOG_FILE"
        if ! run_cmd aws eks delete-access-entry --cluster-name "$CLUSTER_NAME" --principal-arn "$access_entry" --region "$REGION"; then
          entries_deleted=false
        fi
      else
        echo "Skipping service-linked role access entry: $access_entry" >> "$LOG_FILE"
      fi
    done
    sleep 5
    remaining_entries=$(aws eks list-access-entries --cluster-name "$CLUSTER_NAME" --query 'accessEntries[]' --output text --region "$REGION" 2>/dev/null || echo "")
    if [ -z "$remaining_entries" ] && [ "$entries_deleted" = true ]; then
      echo "All non-service-linked EKS access entries deleted" >> "$LOG_FILE"
      break
    else
      echo "Remaining access entries: $remaining_entries, retrying after 10 seconds..." >> "$LOG_FILE"
      attempt=$((attempt + 1))
      sleep 10
    fi
  done
  if [ $attempt -gt $max_attempts ]; then
    echo "Error: Failed to delete all non-service-linked EKS access entries after $max_attempts attempts" >> "$LOG_FILE"
    exit 1
  fi

  nodegroups=$(aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --query 'nodegroups[]' --output text --region "$REGION" 2>/dev/null || echo "")
  if [ -n "$nodegroups" ]; then
    echo "$nodegroups" | while read -r nodegroup; do
      if [ -n "$nodegroup" ]; then
        echo "Deleting node group: $nodegroup" >> "$LOG_FILE"
        run_cmd aws eks delete-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$nodegroup" --region "$REGION" || \
          echo "Failed to delete node group $nodegroup, may be already deleted" >> "$LOG_FILE"
        echo "Waiting for node group $nodegroup to be deleted..." >> "$LOG_FILE"
        run_cmd aws eks wait nodegroup-deleted --cluster-name "$CLUSTER_NAME" --nodegroup-name "$nodegroup" --region "$REGION" || \
          echo "Failed to wait for node group $nodegroup deletion, may be already deleted" >> "$LOG_FILE"
      fi
    done
  else
    echo "No node groups found for cluster $CLUSTER_NAME" >> "$LOG_FILE"
  fi

  echo "Deleting EKS cluster $CLUSTER_NAME..." >> "$LOG_FILE"
  run_cmd aws eks delete-cluster --name "$CLUSTER_NAME" --region "$REGION" || \
    echo "Failed to delete EKS cluster $CLUSTER_NAME, may be already deleted" >> "$LOG_FILE"
  echo "Waiting for EKS cluster $CLUSTER_NAME to be deleted..." >> "$LOG_FILE"
  run_cmd aws eks wait cluster-deleted --name "$CLUSTER_NAME" --region "$REGION" || \
    echo "Failed to wait for EKS cluster $CLUSTER_NAME deletion, may be already deleted" >> "$LOG_FILE"
else
  echo "EKS cluster $CLUSTER_NAME does not exist, skipping EKS cleanup" >> "$LOG_FILE"
fi

# Delete S3 buckets
for bucket in "$STATE_BUCKET" "$APP_BUCKET"; do
  if aws s3api head-bucket --bucket "$bucket" --region "$REGION" >/dev/null 2>&1; then
    echo "Deleting S3 bucket $bucket..." >> "$LOG_FILE"
    run_cmd aws s3 rm s3://"$bucket" --recursive --region "$REGION" || \
      echo "Failed to delete objects in $bucket, may be already empty or deleted" >> "$LOG_FILE"
    run_cmd aws s3api delete-bucket --bucket "$bucket" --region "$REGION" || \
      echo "Failed to delete bucket $bucket, may be already deleted" >> "$LOG_FILE"
  else
    echo "S3 bucket $bucket does not exist, skipping" >> "$LOG_FILE"
  fi
done

# Delete VPC and related resources
vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query 'Vpcs[0].VpcId' --output text --region "$REGION" 2>/dev/null || echo "")
if [ -n "$vpc_id" ] && [ "$vpc_id" != "none" ] && [[ "$vpc_id" =~ ^vpc-[0-9a-f]+$ ]]; then
  echo "Found VPC $vpc_id for $VPC_NAME, cleaning up..." >> "$LOG_FILE"

  # Delete NAT Gateways
  nat_gws=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc_id" --query 'NatGateways[].NatGatewayId' --output text --region "$REGION" 2>/dev/null || echo "")
  for nat_gw in $nat_gws; do
    echo "Deleting NAT gateway $nat_gw..." >> "$LOG_FILE"
    run_cmd aws ec2 delete-nat-gateway --nat-gateway-id "$nat_gw" --region "$REGION" || \
      echo "Failed to delete NAT gateway $nat_gw, may be already deleted" >> "$LOG_FILE"
    echo "Waiting for NAT gateway $nat_gw to be deleted..." >> "$LOG_FILE"
    run_cmd aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$nat_gw" --region "$REGION" || \
      echo "Failed to wait for NAT gateway $nat_gw deletion, may be already deleted" >> "$LOG_FILE"
  done

  # Release Elastic IPs
  eips=$(aws ec2 describe-addresses --filters "Name=tag:Name,Values=$VPC_NAME" --query 'Addresses[].AllocationId' --output text --region "$REGION" 2>/dev/null || echo "")
  for eip in $eips; do
    echo "Releasing Elastic IP $eip..." >> "$LOG_FILE"
    run_cmd aws ec2 release-address --allocation-id "$eip" --region "$REGION" || \
      echo "Failed to release Elastic IP $eip, may be already released" >> "$LOG_FILE"
  done

  # Delete VPC Endpoints
  endpoints=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$vpc_id" --query 'VpcEndpoints[].VpcEndpointId' --output text --region "$REGION" 2>/dev/null || echo "")
  for endpoint in $endpoints; do
    echo "Deleting VPC endpoint $endpoint..." >> "$LOG_FILE"
    run_cmd aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$endpoint" --region "$REGION" || \
      echo "Failed to delete VPC endpoint $endpoint, may be already deleted" >> "$LOG_FILE"
  done

  # Delete Network Interfaces
  enis=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$vpc_id" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text --region "$REGION" 2>/dev/null || echo "")
  for eni in $enis; do
    echo "Deleting network interface $eni..." >> "$LOG_FILE"
    run_cmd aws ec2 delete-network-interface --network-interface-id "$eni" --region "$REGION" || \
      echo "Failed to delete network interface $eni, may be already deleted" >> "$LOG_FILE"
  done

  # Delete Subnets
  subnets=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[].SubnetId' --output text --region "$REGION" 2>/dev/null || echo "")
  for subnet in $subnets; do
    echo "Deleting subnet $subnet..." >> "$LOG_FILE"
    run_cmd aws ec2 delete-subnet --subnet-id "$subnet" --region "$REGION" || \
      echo "Failed to delete subnet $subnet, may be already deleted" >> "$LOG_FILE"
  done

  # Disassociate and delete Route Tables
  main_rt=$(aws ec2 describe-vpcs --vpc-ids "$vpc_id" --query 'Vpcs[0].DefaultRouteTableId' --output text --region "$REGION" 2>/dev/null || echo "")
  if [ -n "$main_rt" ]; then
    associations=$(aws ec2 describe-route-tables --route-table-ids "$main_rt" --query 'RouteTables[0].Associations[].RouteTableAssociationId' --output text --region "$REGION" 2>/dev/null || echo "")
    for assoc in $associations; do
      echo "Disassociating route table association $assoc..." >> "$LOG_FILE"
      run_cmd aws ec2 disassociate-route-table --association-id "$assoc" --region "$REGION" || \
        echo "Failed to disassociate route table $assoc, may be already disassociated" >> "$LOG_FILE"
    done
  fi

  route_tables=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[].RouteTableId' --output text --region "$REGION" 2>/dev/null || echo "")
  for rt in $route_tables; do
    if [ "$rt" != "$main_rt" ]; then
      echo "Deleting route table $rt..." >> "$LOG_FILE"
      run_cmd aws ec2 delete-route-table --route-table-id "$rt" --region "$REGION" || \
        echo "Failed to delete route table $rt, may be already deleted" >> "$LOG_FILE"
    fi
  done

  # Detach and delete Internet Gateway
  igw=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[].InternetGatewayId' --output text --region "$REGION" 2>/dev/null || echo "")
  if [ -n "$igw" ]; then
    echo "Detaching and deleting internet gateway $igw..." >> "$LOG_FILE"
    run_cmd aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc_id" --region "$REGION" || \
      echo "Failed to detach internet gateway $igw, may be already detached" >> "$LOG_FILE"
    run_cmd aws ec2 delete-internet-gateway --internet-gateway-id "$igw" --region "$REGION" || indoor
      echo "Failed to delete internet gateway $igw, may be already deleted" >> "$LOG_FILE"
  fi

  # Delete Security Groups (except default)
  default_sg=$(aws ec2 describe-vpcs --vpc-ids "$vpc_id" --query 'Vpcs[0].DefaultSecurityGroupId' --output text --region "$REGION" 2>/dev/null || echo "")
  sgs=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --query 'SecurityGroups[].GroupId' --output text --region "$REGION" 2>/dev/null || echo "")
  for sg in $sgs; do
    if [ "$sg" != "$default_sg" ]; then
      echo "Deleting security group $sg..." >> "$LOG_FILE"
      run_cmd aws ec2 delete-security-group --group-id "$sg" --region "$REGION" || \
        echo "Failed to delete security group $sg, may be already deleted" >> "$LOG_FILE"
    fi
  done

  # Delete VPC
  echo "Deleting VPC $vpc_id..." >> "$LOG_FILE"
  run_cmd aws ec2 delete-vpc --vpc-id "$vpc_id" --region "$REGION" || \
    echo "Failed to delete VPC $vpc_id, may be already deleted" >> "$LOG_FILE"
else
  echo "VPC $VPC_NAME does not exist or is invalid, skipping VPC cleanup" >> "$LOG_FILE"
fi

# Delete IAM roles and policies
roles=("ecommerce-cluster-cluster-role" "ecommerce-cluster-node-role" "terraform-admin" "ecommerce-cluster-alb-controller")
for role in "${roles[@]}"; do
  if aws iam get-role --role-name "$role" >/dev/null 2>&1; then
    echo "Deleting IAM role $role..." >> "$LOG_FILE"
    policies=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null || echo "")
    for policy in $policies; do
      echo "Detaching policy $policy from $role..." >> "$LOG_FILE"
      run_cmd aws iam detach-role-policy --role-name "$role" --policy-arn "$policy" || \
        echo "Failed to detach policy $policy from $role, may be already detached" >> "$LOG_FILE"
    done
    inline_policies=$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames' --output text 2>/dev/null || echo "")
    for policy in $inline_policies; do
      echo "Deleting inline policy $policy from $role..." >> "$LOG_FILE"
      run_cmd aws iam delete-role-policy --role-name "$role" --policy-name "$policy" || \
        echo "Failed to delete inline policy $policy from $role, may be already deleted" >> "$LOG_FILE"
    done
    run_cmd aws iam delete-role --role-name "$role" || \
      echo "Failed to delete role $role, may be already deleted" >> "$LOG_FILE"
  else
    echo "IAM role $role does not exist, skipping" >> "$LOG_FILE"
  fi
done

# Delete all custom policies
custom_policies=$(aws iam list-policies --scope Local --query 'Policies[?contains(PolicyName, `ecommerce-cluster-`) || contains(PolicyName, `TerraformAdmin`)].{Arn:Arn,Name:PolicyName}' --output json 2>/dev/null || echo "[]")
if [ -n "$custom_policies" ] && [ "$custom_policies" != "[]" ]; then
  echo "$custom_policies" | jq -r '.[] | .Arn + " " + .Name' | while read -r arn name; do
    echo "Checking attachments for policy $name ($arn)..." >> "$LOG_FILE"
    attached_roles=$(aws iam list-entities-for-policy --policy-arn "$arn" --query 'PolicyRoles[].RoleName' --output text 2>/dev/null || echo "")
    for role in $attached_roles; do
      echo "Detaching policy $arn from role $role..." >> "$LOG_FILE"
      run_cmd aws iam detach-role-policy --role-name "$role" --policy-arn "$arn" || \
        echo "Failed to detach policy $arn from $role, may be already detached" >> "$LOG_FILE"
    done
    echo "Deleting custom policy $name ($arn)..." >> "$LOG_FILE"
    run_cmd aws iam delete-policy --policy-arn "$arn" || \
      echo "Failed to delete policy $name ($arn), may be already deleted" >> "$LOG_FILE"
  done
else
  echo "No custom policies found" >> "$LOG_FILE"
fi

# Final verification
echo "Verifying cleanup..." >> "$LOG_FILE"
aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1 && \
  echo "Warning: EKS cluster $CLUSTER_NAME still exists" >> "$LOG_FILE" || \
  echo "EKS cluster $CLUSTER_NAME deleted" >> "$LOG_FILE"
aws s3api head-bucket --bucket "$STATE_BUCKET" --region "$REGION" >/dev/null 2>&1 && \
  echo "Warning: S3 bucket $STATE_BUCKET still exists" >> "$LOG_FILE" || \
  echo "S3 bucket $STATE_BUCKET deleted" >> "$LOG_FILE"
aws s3api head-bucket --bucket "$APP_BUCKET" --region "$REGION" >/dev/null 2>&1 && \
  echo "Warning: S3 bucket $APP_BUCKET still exists" >> "$LOG_FILE" || \
  echo "S3 bucket $APP_BUCKET deleted" >> "$LOG_FILE"
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --region "$REGION" >/dev/null 2>&1 && \
  echo "Warning: VPC $VPC_NAME still exists" >> "$LOG_FILE" || \
  echo "VPC $VPC_NAME deleted" >> "$LOG_FILE"
for role in "${roles[@]}"; do
  aws iam get-role --role-name "$role" >/dev/null 2>&1 && \
    echo "Warning: IAM role $role still exists" >> "$LOG_FILE" || \
    echo "IAM role $role deleted" >> "$LOG_FILE"
done
custom_policies=$(aws iam list-policies --scope Local --query 'Policies[?contains(PolicyName, `ecommerce-cluster-`) || contains(PolicyName, `TerraformAdmin`)].PolicyName' --output text 2>/dev/null || echo "")
if [ -n "$custom_policies" ]; then
  echo "Warning: Custom policies still exist: $custom_policies" >> "$LOG_FILE"
else
  echo "All custom policies deleted" >> "$LOG_FILE"
fi

echo "Cleanup completed at $(date)" >> "$LOG_FILE"
