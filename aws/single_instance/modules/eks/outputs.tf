# File 33: modules/eks/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "eks_cluster_sg_id" {
  description = "Security group ID for EKS cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
