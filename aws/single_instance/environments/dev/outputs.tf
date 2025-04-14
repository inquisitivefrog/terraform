# File 8: environments/dev/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "eks_cluster_endpoint" {
  value = module.eks.eks_cluster_endpoint
  description = "EKS cluster API endpoint"
}

output "eks_cluster_name" {
  value = module.eks.eks_cluster_name
  description = "EKS cluster name"
}

output "eks_cluster_ca_certificate" {
  value = module.eks.eks_cluster_ca_certificate
  description = "EKS cluster CA certificate"
}

output "sns_topic_example_arn" {
  description = "The ARN of the example SNS topic"
  value       = module.messages.sns_topic_example_arn
}
