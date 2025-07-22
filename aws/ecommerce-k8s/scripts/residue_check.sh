#!/bin/bash

aws s3api delete-bucket --bucket bluedragon-ecommerce-terraform-state --region us-east-1
aws s3api list-buckets --query 'Buckets[?Name==`bluedragon-ecommerce-terraform-state`]' --region us-east-1
aws ec2 describe-route-tables --route-table-ids rtb-0e294f5f398a61444 --region us-east-1 --query 'RouteTables[0].{Associations:Associations,Main:Associations[].Main}'
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0a1c7d39e932789c6" --region us-east-1
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=vpc-0a1c7d39e932789c6" --region us-east-1
aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=vpc-0a1c7d39e932789c6" --region us-east-1
aws ec2 describe-security-groups --group-ids sg-01f2433be3b698e91 --region us-east-1
aws ec2 describe-vpcs --vpc-ids vpc-0a1c7d39e932789c6 --region us-east-1

aws eks describe-cluster --name ecommerce-cluster --region us-east-1
aws eks list-nodegroups --cluster-name ecommerce-cluster --region us-east-1

aws ec2 describe-vpcs --vpc-ids vpc-0a1c7d39e932789c6 --region us-east-1
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0a1c7d39e932789c6" --region us-east-1
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-0a1c7d39e932789c6" --region us-east-1
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-0a1c7d39e932789c6" --region us-east-1

aws s3api list-buckets --query 'Buckets[?Name==`bluedragon-ecommerce-terraform-state` || Name==`blued-ecommerce-app-us-east-1-prod`]' --region us-east-1
aws iam list-roles --query 'Roles[?RoleName==`ecommerce-cluster-node-role` || RoleName==`ecommerce-cluster-cluster-role` || RoleName==`terraform-admin`]'

aws iam list-roles --query 'Roles[?RoleName==`ecommerce-cluster-node-role` || RoleName==`ecommerce-cluster-cluster-role` || RoleName==`terraform-admin`]'
aws iam list-attached-role-policies --role-name ecommerce-cluster-node-role   
aws iam list-attached-role-policies --role-name ecommerce-cluster-cluster-role
aws iam list-attached-role-policies --role-name terraform-admin            
aws iam list-roles --query 'Roles[?RoleName==`ecommerce-cluster-node-role` || RoleName==`ecommerce-cluster-cluster-role` || RoleName==`bluedragon-admin`]'
aws iam list-attached-role-policies --role-name ecommerce-cluster-cluster-role
aws iam list-attached-role-policies --role-name ecommerce-cluster-node-role
