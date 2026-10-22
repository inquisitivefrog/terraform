# File 8: environments/dev/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.eks_cluster_name
}

output "vpc_id" {
  description = "VPC ID; scripts/check_resources.sh scopes its network checks to it"
  value       = module.vpc.vpc_id
}

output "kubeconfig_command" {
  description = "Run this to point kubectl at the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --profile ${var.aws_profile} --name ${module.eks.eks_cluster_name} --alias eks-${var.env}"
}

output "eks_cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = module.eks.eks_cluster_ca_certificate
}

output "sns_topic_example_arn" {
  description = "The ARN of the example SNS topic"
  value       = module.messages.sns_topic_example_arn
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint; connect with TLS and the AUTH token"
  value       = module.cache.redis_primary_endpoint
}

output "redis_auth_token" {
  description = "Redis AUTH token (terraform output -raw redis_auth_token)"
  value       = module.cache.redis_auth_token
  sensitive   = true
}
