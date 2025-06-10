# modules/networking/outputs.tf
output "eks_control_plane_security_group_rule_id" {
  description = "ID of the EKS control plane ingress security group rule"
  value       = aws_security_group_rule.eks_control_plane_ingress.id
}

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}
