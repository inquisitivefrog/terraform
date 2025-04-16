# File 19: modules/identity/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "ecs_task_execution_role_arn" {
  value = var.create_iam_resources ? aws_iam_role.ecs_task_execution_role[0].arn : data.aws_iam_role.ecs_task_execution_role[0].arn
}

output "ec2_instance_profile_name" {
  value = var.create_iam_resources ? aws_iam_instance_profile.ec2_profile[0].name : "EC2Profile" 
}

output "ec2_instance_role_arn" {
  value       = var.create_iam_resources ? aws_iam_role.ec2_role[0].arn : data.aws_iam_role.ec2_role[0].arn
  description = "ARN of the EC2 instance role"
}

output "ec2_role_name" {
  value       = aws_iam_role.ec2_role[0].name
  description = "Name of the EC2 IAM role"
}

output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_node.arn
}

output "eks_cluster_policy_attachments" {
  value = [
    aws_iam_role_policy_attachment.eks_cluster_policy.id,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller.id
  ]
}

output "eks_node_policy_attachments" {
  value = [
    aws_iam_role_policy_attachment.eks_worker_node_policy.id,
    aws_iam_role_policy_attachment.eks_cni_policy.id,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only.id
  ]
}
