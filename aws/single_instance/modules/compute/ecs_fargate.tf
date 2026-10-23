# File 17: modules/compute/ecs.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
# https://registry.terraform.io/providers/-/aws/4.57.0/docs/resources/ecs_task_definition

# Container Insights writes here. Created by Terraform (before the cluster) so
# destroy removes it; left to ECS, it outlived every destroy.
resource "aws_cloudwatch_log_group" "container_insights" {
  # checkov:skip=CKV_AWS_158:performance metrics only; default encryption
  # checkov:skip=CKV_AWS_338:one day is the retention ECS itself uses
  name              = "/aws/ecs/containerinsights/ecs-cluster-${var.env}/performance"
  retention_in_days = 1
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "ecs-cluster-${var.env}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  depends_on = [aws_cloudwatch_log_group.container_insights]
}

# Task Definition
resource "aws_ecs_task_definition" "service" {
  family                   = "tasks-${var.env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "nginx",
      image     = "nginx:latest", # Replace with your Docker image
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
      # nginx writes its cache, pid file and temp files at startup; with only a
      # read-only root it exited 1 and the service restarted it every ~30s.
      mountPoints = [
        { sourceVolume = "nginx-cache", containerPath = "/var/cache/nginx", readOnly = false },
        { sourceVolume = "run", containerPath = "/run", readOnly = false },
        { sourceVolume = "tmp", containerPath = "/tmp", readOnly = false },
      ]
    }
  ])

  # Fargate ephemeral task storage (no host path): writable scratch for the
  # paths above while the root filesystem stays read-only (CKV_AWS_336).
  volume {
    name = "nginx-cache"
  }
  volume {
    name = "run"
  }
  volume {
    name = "tmp"
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.vpc_subnet_private_id]
    security_groups  = [var.sg_public_ec2_id]
    assign_public_ip = false
  }
}
