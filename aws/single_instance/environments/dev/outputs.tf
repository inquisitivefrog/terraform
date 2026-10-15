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

output "eks_cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = module.eks.eks_cluster_ca_certificate
}

output "sns_topic_example_arn" {
  description = "The ARN of the example SNS topic"
  value       = module.messages.sns_topic_example_arn
}
