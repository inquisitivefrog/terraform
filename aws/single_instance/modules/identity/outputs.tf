# File 19: modules/identity/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}
