#!/bin/bash

# Define regions
REGIONS=(
  "us-west-1"
  "us-west-2"
) 
  
# Inspect resources
for region in "${REGIONS[@]}"; do
  scan_tf "$region"
done

# Validate AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Error: Invalid or missing AWS credentials"
  exit 1
fi

# Function to destroy Terraform Kubernetes resources
scan_tf() {
  local region=$1
  aws batch describe-job-queues --region $region

  aws budgets describe-budgets --account-id 084375569056 --query 'Budgets[*].[BudgetName,CalculatedSpend.ActualSpend.Amount,TimePeriod.Start,TimePeriod.End]' --output text

  aws cloudfront list-cache-policies --region $region
  aws cloudfront list-distributions --region $region
  aws cloudfront list-functions --region $region
  aws cloudfront list-key-groups --region $region
  aws cloudfront list-public-keys --region $region

  aws cloudtrail describe-trails --region $region
  aws cloudtrail list-channels --region $region

  aws ec2 describe-addresses --query 'Addresses[*].[PublicIp,AllocationId,AssociationId]' --region $region --output table
  aws ec2 describe-flow-logs --query 'FlowLogs[*].[FlowLogId,VpcId,LogDestination]' --region $region --output table
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,Tags]' --region $region --output table
  aws ec2 describe-internet-gateways --query 'InternetGateways[*].[InternetGatewayId,Attachments[*].VpcId]' --region $region --output table
  aws ec2 describe-key-pairs --query 'KeyPairs[*].[KeyName]' --region $region --output table
  aws ec2 describe-local-gateways --region $region --output table
  aws ec2 describe-nat-gateways --query 'NatGateways[*].[NatGatewayId,State,VpcId,Tags]' --region $region --output table
  aws ec2 describe-network-interfaces --region $region --filters Name=vpc-id
  aws ec2 describe-route-tables --query 'RouteTables[*].[RouteTableId,VpcId]' --region $region --output table
  aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId,GroupName,VpcId,Tags]' --region $region --output table
  aws ec2 describe-security-group-rules --query 'SecurityGroupRules[*].[SecurityGroupRuleId,GroupId]' --region $region --output table
  aws ec2 describe-subnets --query 'Subnets[*].[SubnetArn,SubnetId,VpcId,CidrBlock]' --region $region --output table
  aws ec2 describe-tags --region $region
  aws ec2 describe-transit-gateways --region $region
  aws ec2 describe-volumes --region $region
  aws ec2 describe-vpcs --region us-west-1 --query 'Vpcs[*].{VpcId:VpcId,CidrBlock:CidrBlock,Tags:Tags}' --region $region --output table
  aws ec2 describe-vpn-gateways --region $region
  aws ec2 describe-vpn-connections --region $region

  aws ecs list-account-settings --region $region --output table
  aws ecs list-clusters --query 'clusterArns[*]' --region $region --output table
  aws ecs list-task-definitions --query 'taskDefinitionArns[*]' --region $region --output table

  aws eks list-clusters --region $region

  aws elasticache describe-cache-clusters --query 'CacheClusters[*].[CacheClusterId,CacheNodeType,Engine,CacheClusterStatus,Tags]' --output table
  aws elasticache describe-cache-subnet-groups --query 'CacheSubnetGroups[*]' --region $region
  aws elasticache describe-events --region $region --output table
  aws elasticache describe-global-replication-groups --region $region --output table
  aws elasticache describe-replication-groups --region $region --output table
  aws elasticache describe-user-groups --region $region --output table
  aws elasticache describe-users --query 'Users[*].[UserName,Status,ARN]' --region $region --output table

  aws elbv2 describe-account-limits --query 'Limits[*].[Name,Max]' --region $region --output table
  aws elbv2 describe-load-balancers --region $region

  aws iam list-access-keys --query 'AccessKeyMetadata[*].[UserName,AccessKeyId,Status]' --region $region --output table
  aws iam list-groups --query 'Groups[*].[GroupName,Arn]' --region $region --output table
  aws iam list-instance-profiles --query 'InstanceProfiles[*].Roles[*].AssumeRolePolicyDocument.Statement[*].Action' --region $region --output table
  aws iam list-policies --query 'Policies[*].[PolicyName,Arn]' --region $region --output table
  aws iam list-roles --query 'Roles[*].[RoleName,Arn]' --output table
  aws iam list-users --query 'Users[*].[UserName,Arn]' --region $region --output table

  aws kms list-aliases --query 'Aliases[*].[AliasName,AliasArn]' --region $region --output table
  aws kms describe-custom-key-stores --region $region --output table
  aws kms list-keys --query 'Keys[*].[KeyId,KeyArn]' --region $region --output table
  aws kms schedule-key-deletion --key-id <key-id> --pending-window-in-days 7

  aws launch-wizard list-deployments --region $region --output table
  aws launch-wizard list-workloads --region $region --output table

  aws s3 ls
  aws s3api list-buckets --query 'Buckets[].Name' --output text

  aws sns list-platform-applications --query 'PlatformApplications[*].[PlatformApplicationArn]' --region $region --output table
  aws sns list-subscriptions --query 'Subscription[*].[SubscriptionId]' --region $region --output table
  aws sns list-topics --query 'Topics[*].TopicArn' --region $region --output table

  aws sqs list-queues --region $region --output table

