#!/usr/bin/env bash

# List AWS resources (read-only describe/list calls)
# Run from /Users/tim/Documents/workspace/sre/terraform/aws/

EXPECTED_DIR="/Users/tim/Documents/workspace/sre/terraform/aws"
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "$EXPECTED_DIR" ]; then
  echo "Error: Must run from $EXPECTED_DIR"
  exit 1
fi

source "$(dirname "$0")/aws_env.sh"
require_account
AWS_REGION=${REGIONS[0]} # dev and prod both


aws elb describe-load-balancers --region "$AWS_REGION"
aws elbv2 describe-load-balancers --region "$AWS_REGION" 

aws ec2 describe-vpcs --region "$AWS_REGION" 
aws ec2 describe-subnets --region "$AWS_REGION" 
aws ec2 describe-network-interfaces --region "$AWS_REGION"
aws ec2 describe-security-groups --region "$AWS_REGION" 
aws ec2 describe-route-tables --region "$AWS_REGION"
aws ec2 describe-nat-gateways --region "$AWS_REGION"
aws ec2 describe-internet-gateways --region "$AWS_REGION"

aws elasticache describe-cache-clusters --region "$AWS_REGION"
aws elasticache describe-replication-groups --region "$AWS_REGION"
aws elasticache describe-users --region "$AWS_REGION"
aws elasticache describe-events --region "$AWS_REGION"

aws ec2 describe-instances --region "$AWS_REGION"

aws eks list-clusters --region "$AWS_REGION"
aws sns list-topics --region "$AWS_REGION"
aws logs describe-log-groups --log-group-name-prefix /aws/ecs/containerinsights/ecs-cluster- --region "$AWS_REGION"
aws logs describe-log-groups --log-group-name-prefix /aws/eks/my-eks-cluster --region "$AWS_REGION"
aws logs describe-log-groups --region "$AWS_REGION"

aws s3 ls
