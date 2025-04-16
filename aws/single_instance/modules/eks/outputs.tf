# File 33: modules/eks/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "eks_cluster_ca_certificates" {
  value       = { for k, v in aws_eks_cluster.this : k => v.certificate_authority[0].data }
  description = "CA certificates of EKS clusters"
}

output "eks_cluster_endpoints" {
  value       = { for k, v in aws_eks_cluster.this : k => v.endpoint }
  description = "Endpoints of EKS clusters"
}

output "eks_cluster_names" {
  value       = { for k, v in aws_eks_cluster.this : k => v.name }
  description = "Names of EKS clusters"
}

output "eks_cluster_sg_id" {
  value       = aws_eks_cluster.this["dev1"].vpc_config[0].cluster_security_group_id
  description = "Security group ID for EKS cluster"
}
