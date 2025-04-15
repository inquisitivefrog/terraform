# File 8: environments/dev/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "eks_cluster_ca_certificates" {
  value       = module.eks.eks_cluster_ca_certificates
  description = "EKS cluster CA certificates"
}

output "eks_cluster_endpoints" {
  value       = module.eks.eks_cluster_endpoints
  description = "EKS cluster API endpoints"
}

output "eks_cluster_names" {
  value       = module.eks.eks_cluster_names
  description = "EKS cluster names"
}

output "sns_topic_example_arn" {
  description = "The ARN of the example SNS topic"
  value       = module.messages.sns_topic_example_arn
}
