#!/bin/bash

# List AWS resources (read-only describe/list calls)
# Run from /Users/tim/Documents/workspace/sre/terraform/aws/

EXPECTED_DIR="/Users/tim/Documents/workspace/sre/terraform/aws"
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "$EXPECTED_DIR" ]; then
  echo "Error: Must run from $EXPECTED_DIR"
  exit 1
fi

# Default region (override with environment variable if needed)
AWS_REGION=${AWS_REGION:-us-east-1}


aws elb describe-load-balancers --region us-west-1
aws elbv2 describe-load-balancers --region us-west-1 

aws ec2 describe-vpcs --region us-west-2 
aws ec2 describe-subnets --region us-west-2 
aws ec2 describe-network-interfaces --region us-west-2
aws ec2 describe-security-groups --region us-west-2 
aws ec2 describe-route-tables --region us-west-2
aws ec2 describe-nat-gateways --region us-west-2
aws ec2 describe-internet-gateways --region us-west-2

aws elasticache describe-cache-clusters --region us-west-2
aws elasticache describe-replication-groups --region us-west-2
aws elasticache describe-users --region us-west-2
aws elasticache describe-events --region us-west-2

aws ec2 describe-instances --region us-west-2

aws eks list-clusters --region us-west-2
aws sns list-topics --region us-west-2
aws logs describe-log-groups --log-group-name-prefix /aws/ecs/containerinsights/ecs-cluster/performance --region us-west-2
aws logs describe-log-groups --log-group-name-prefix /aws/eks/my-eks-cluster --region us-west-2
aws logs describe-log-groups --region us-west-2

aws s3 ls
