# File 20: modules/identity/iam_ecs.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role.html
# https://registry.terraform.io/providers/hashicorp/aws/3.0.0/docs/resources/iam_policy_attachment

# IAM Role for ECS tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  count = var.create_iam_resources ? 1 : 0
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_role" "ecs_task_execution_role" {
  count = var.create_iam_resources ? 0 : 1
  name = "ecsTaskExecutionRole"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = var. create_iam_resources ? aws_iam_role.ecs_task_execution_role[0].name: data.aws_iam_role.ecs_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
