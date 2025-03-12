# File 17: modules/compute/ecs.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service  
# https://registry.terraform.io/providers/-/aws/4.57.0/docs/resources/ecs_task_definition

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "ecs-cluster"
  setting {
    name = "containerInsights"
    value = "enabled"
  }
}

# Task Definition
resource "aws_ecs_task_definition" "service" {
  family                   = "tasks-prod"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "nginx",
      image     = "nginx:latest",  # Replace with your Docker image
      cpu       = 256,
      memory    = 512,
      essential = true,
      portMappings = [
        {
          containerPort = 80,
          hostPort      = 80
        }
      ],
      readonlyRootFilesystem = true
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.vpc_subnet_public_id]
    security_groups  = [var.sg_public_ec2_id]
    assign_public_ip = true
  }
}
