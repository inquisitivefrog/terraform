#!/bin/bash

# Detach policies
aws iam detach-role-policy --role-name ecommerce-cluster-cluster-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam detach-role-policy --role-name ecommerce-cluster-cluster-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController

# Delete the role
aws iam delete-role --role-name ecommerce-cluster-cluster-role

# Detach policies
aws iam detach-role-policy --role-name ecommerce-cluster-node-role --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam detach-role-policy --role-name ecommerce-cluster-node-role --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam detach-role-policy --role-name ecommerce-cluster-node-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam detach-role-policy --role-name ecommerce-cluster-node-role --policy-arn arn:aws:iam::084375569056:policy/ecommerce-cluster-EKSNodeGroupELBPolicy

# Delete the custom policy
aws iam delete-policy --policy-arn arn:aws:iam::084375569056:policy/ecommerce-cluster-EKSNodeGroupELBPolicy

# Delete the role
aws iam delete-role --role-name ecommerce-cluster-node-role

# Detach policies
aws iam detach-role-policy --role-name terraform-admin --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam detach-role-policy --role-name terraform-admin --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam detach-role-policy --role-name terraform-admin --policy-arn arn:aws:iam::084375569056:policy/TerraformAdminBackendPolicy
aws iam detach-role-policy --role-name terraform-admin --policy-arn arn:aws:iam::084375569056:policy/TerraformAdminEC2Policy
aws iam detach-role-policy --role-name terraform-admin --policy-arn arn:aws:iam::084375569056:policy/TerraformAdminELBOtherPolicy
aws iam detach-role-policy --role-name terraform-admin --policy-arn arn:aws:iam::084375569056:policy/TerraformAdminACMPolicy
aws iam detach-role-policy --role-name terraform-admin --policy-arn arn:aws:iam::084375569056:policy/TerraformAdminEKSPolicy

# Delete custom policies
aws iam delete-policy --policy-arn arn:aws:iam::084375569056:policy/TerraformAdminBackendPolicy
aws iam delete-policy --policy-arn arn:aws:iam::084375569056:policy/TerraformAdminEC2Policy
aws iam detach-role-policy --role-name terraform-admin --policy-arn arn:aws:iam::084375569056:policy/TerraformAdminELBOtherPolicy
aws iam delete-policy --role-name terraform-admin --policy-arn arn:aws:iam::084375569056:policy/TerraformAdminACMPolicy
aws iam delete-policy --policy-arn arn:aws:iam::084375569056:policy/TerraformAdminEKSPolicy

# Delete the role
aws iam delete-role --role-name terraform-admin


