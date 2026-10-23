output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "eks_managed_node_groups" {
  value = {
    default = {
      iam_role_name = var.node_role_arn
    }
  }
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster" {
  description = "The EKS cluster resource"
  value       = aws_eks_cluster.this
}
