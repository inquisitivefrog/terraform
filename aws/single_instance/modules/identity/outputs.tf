# File 19: modules/identity/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "ecs_task_execution_role_arn" {
  value = var.create_iam_resources ? aws_iam_role.ecs_task_execution_role[0].arn : data.aws_iam_role.ecs_task_execution_role.arn
}

output "ec2_instance_profile_name" {
  value = var.create_iam_resources ? aws_iam_instance_profile.ec2_profile[0].name : "EC2Profile" 
}
