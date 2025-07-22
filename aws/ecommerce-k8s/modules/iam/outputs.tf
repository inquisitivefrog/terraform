# modules/iam/outputs.tf
output "eks_cluster_role_arn" {
  value = aws_iam_role.eks.arn
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "terraform_role_arn" {
  value = aws_iam_role.terraform_admin.arn
}
