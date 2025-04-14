#!/bin/bash

aws ec2 describe-vpcs --region us-west-1 --query 'Vpcs[*].{VpcId:VpcId,CidrBlock:CidrBlock,Tags:Tags}' --output table
aws ec2 describe-vpcs --region us-west-2 --query 'Vpcs[*].[VpcId,CidrBlock,Tags]' --output table
aws ec2 describe-nat-gateways --query 'NatGateways[*].[NatGatewayId,State,VpcId,Tags]' --output table
aws ec2 describe-internet-gateways --query 'InternetGateways[*].[InternetGatewayId,Attachments[*].VpcId,Tags]' --output table
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,Tags]' --output table
aws elasticache describe-cache-clusters --query 'CacheClusters[*].[CacheClusterId,CacheNodeType,Engine,CacheClusterStatus,Tags]' --output table
aws sqs list-queues
aws sqs get-queue-attributes --queue-url <queue-url> --attribute-names All
aws sns list-topics --query 'Topics[*].TopicArn' --output table
aws sns list-subscriptions-by-topic --topic-arn <topic-arn>
aws eks list-clusters
aws eks list-nodegroups --cluster-name <cluster-name>
aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId,GroupName,VpcId,Tags]' --output table
aws ec2 describe-route-tables --query 'RouteTables[*].[RouteTableId,VpcId,Tags]' --output table
aws iam list-roles --query 'Roles[*].[RoleName,Arn]' --output table
aws kms list-keys
# aws kms describe-key --key-id <key-id>
# aws kms schedule-key-deletion --key-id <key-id> --pending-window-in-days 7
aws ec2 describe-flow-logs --query 'FlowLogs[*].[FlowLogId,VpcId,LogDestination]' --output table
aws ec2 describe-addresses --query 'Addresses[*].[PublicIp,AllocationId,AssociationId]' --output table
aws s3 ls
# aws s3 ls s3://<bucket-name> --recursive

