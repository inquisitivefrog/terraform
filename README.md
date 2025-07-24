# terraform
Configuration Knowledge for Future Reference

AWS

1. tfstate: create S3 bucket for terraform.tfstate
            in dev, prod environments

2. single_instance: create resources 
   a. networking: VPC, subnets, EIP, NAT, IGW, security group, route table
   b. identity: IAM user, group, role, policy, instance_profile
   c. cache: elasticache cluster
   d. compute: EC2, ECS cluster
   e. eks: EKS cluster, EKS node group
   f. messages: SNS topic
   g. kms: KMS key, alias
   h. kubernetes: namespace, RBAC, quota, secret, ingress, deployment

3. ecommerce-k8s: create Kubernetes deployments and services and resources
   a. networking: VPC, subnets, EIP, NAT, IGW, security group, route table
   b. identity: IAM role, IAM policy
   c. cluster_config: EKS access entry, EKS access policy
   d. eks: EKS cluster, EKS node group, IAM OpenID
   e. helm: helm_release
   f. rbac: kubernetes_manifest
   g. s3: S3 bucket
   h. tiller: kubernetes_service_account, deployment, service
   i. sample-app: kubernetes_deployment, kubernetes_service
