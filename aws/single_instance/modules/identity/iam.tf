# File 22: modules/identity/iam.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_membership
# https://registry.terraform.io/providers/-/aws/latest/docs/resources/iam_group_policy_attachment

# Resource ARNs for DeveloperPolicy and AdminPolicy, matched by name in any
# region so one copy of these shared policies covers dev (us-west-2) and
# prod (us-west-1), and replacing an instance doesn't rewrite them. Names
# come from the storage, cache, compute and messages modules.
locals {
  arns = {
    s3_bucket     = "arn:aws:s3:::bluedragon-dev-bucket-*" # both envs use this prefix
    ec2_instances = "arn:aws:ec2:*:${var.account_id}:instance/*"
    elasticache = [
      "arn:aws:elasticache:*:${var.account_id}:replicationgroup:redis-single-instance",
      "arn:aws:elasticache:*:${var.account_id}:cluster:redis-single-instance-*",
    ]
    ecs = [
      "arn:aws:ecs:*:${var.account_id}:cluster/ecs-cluster",
      "arn:aws:ecs:*:${var.account_id}:service/ecs-cluster/ecs-service",
    ]
    kms_keys = "arn:aws:kms:*:${var.account_id}:key/*"
    sns_topics = [
      "arn:aws:sns:*:${var.account_id}:example-topic",
      "arn:aws:sns:*:${var.account_id}:custom-topic.fifo",
    ]
  }
}

resource "aws_iam_user" "sre" {
  count = var.create_iam_resources ? 1 : 0
  name  = "sre"
  path  = "/"
  # checkov:skip=CKV_AWS_273:SSO not implemented yet, using IAM users temporarily
}

resource "aws_iam_user" "dba" {
  count = var.create_iam_resources ? 1 : 0
  name  = "dba"
  path  = "/"
  # checkov:skip=CKV_AWS_273:SSO not implemented yet, using IAM users temporarily
}

resource "aws_iam_group" "operations" {
  count = var.create_iam_resources ? 1 : 0
  name  = "operations"
  # tfsec:ignore:aws-iam-enforce-group-mfa
}

# Shared IAM (one copy per account, so only the environment with
# create_iam_resources = true manages it; the other would overwrite it, and
# destroying it would delete it for both).
resource "aws_iam_group_membership" "operations_membership" {
  count = var.create_iam_resources ? 1 : 0
  name  = "operations-membership"
  users = [
    aws_iam_user.sre[0].name,
    aws_iam_user.dba[0].name,
  ]
  group = aws_iam_group.operations[0].name
}

resource "aws_iam_group_policy_attachment" "attach_assume_admin_policy" {
  count      = var.create_iam_resources ? 1 : 0
  group      = aws_iam_group.operations[0].name
  policy_arn = aws_iam_policy.assume_admin_role_policy[0].arn
}

resource "aws_iam_role" "developer_role" {
  count = var.create_iam_resources ? 1 : 0
  name  = "Developer"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_role" "developer_role" {
  count = var.create_iam_resources ? 0 : 1
  name  = "Developer"
}

resource "aws_iam_policy" "developer_policy" {
  count       = var.create_iam_resources ? 1 : 0
  name        = "DeveloperPolicy"
  description = "Policy for developers"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Describe actions don't support resource-level permissions.
        Action   = ["ec2:Describe*"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = [local.arns.s3_bucket, "${local.arns.s3_bucket}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "developer_attach" {
  count      = var.create_iam_resources ? 1 : 0
  role       = aws_iam_role.developer_role[0].name
  policy_arn = aws_iam_policy.developer_policy[0].arn
}

resource "aws_iam_role" "admin_role" {
  count = var.create_iam_resources ? 1 : 0
  name  = "Admin"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_role" "admin_role" {
  count = var.create_iam_resources ? 0 : 1
  name  = "Admin"
}

resource "aws_iam_policy" "assume_admin_role_policy" {
  count       = var.create_iam_resources ? 1 : 0
  name        = "AssumeAdminRolePolicy"
  description = "Policy to allow assuming Admin role"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = var.create_iam_resources ? aws_iam_role.admin_role[0].arn : data.aws_iam_role.admin_role[0].arn
      }
    ]
  })
}

resource "aws_iam_policy" "admin_policy" {
  count       = var.create_iam_resources ? 1 : 0
  name        = "AdminPolicy"
  description = "Policy for administrators"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:Describe*"]
        Resource = "*"
      },
      {
        # Instance IDs aren't known in advance; match this project's tag.
        Effect   = "Allow"
        Action   = ["ec2:*"]
        Resource = local.arns.ec2_instances
        Condition = {
          StringEquals = { "aws:ResourceTag/Project" = var.project_tag }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "elasticache:*",
          "ecs:*",
          "kms:*",
          "sns:*",
        ]
        Resource = concat(
          [local.arns.s3_bucket, "${local.arns.s3_bucket}/*"],
          local.arns.elasticache,
          local.arns.ecs,
          [local.arns.kms_keys],
          local.arns.sns_topics,
        )
      },
      {
        Effect = "Allow"
        Action = [
          "iam:List*",
          "iam:Get*",
          "iam:Describe*",
          "iam:CreateRole",
          "iam:UpdateRole",
          "iam:DeleteRole",
          "iam:CreatePolicy",
          "iam:UpdatePolicy",
          "iam:DeletePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy"
        ]
        Resource = [
          var.create_iam_resources ? aws_iam_role.ec2_role[0].arn : data.aws_iam_role.ec2_role[0].arn,
          var.create_iam_resources ? aws_iam_role.ecs_task_execution_role[0].arn : data.aws_iam_role.ecs_task_execution_role[0].arn,
          var.create_iam_resources ? aws_iam_role.admin_role[0].arn : data.aws_iam_role.admin_role[0].arn,
          var.create_iam_resources ? aws_iam_role.developer_role[0].arn : data.aws_iam_role.developer_role[0].arn,
          "arn:aws:iam::${var.account_id}:policy/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          var.create_iam_resources ? aws_iam_role.ec2_role[0].arn : data.aws_iam_role.ec2_role[0].arn,
          var.create_iam_resources ? aws_iam_role.ecs_task_execution_role[0].arn : data.aws_iam_role.ecs_task_execution_role[0].arn
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ec2.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  count      = var.create_iam_resources ? 1 : 0
  role       = aws_iam_role.admin_role[0].name
  policy_arn = aws_iam_policy.admin_policy[0].arn
}

resource "aws_iam_instance_profile" "operations_profile" {
  count = var.create_iam_resources ? 1 : 0
  name  = "operations_profile"
  role  = var.create_iam_resources ? aws_iam_role.admin_role[0].name : data.aws_iam_role.admin_role[0].name
}

resource "aws_iam_group_policy" "operations_assume_role" {
  count = var.create_iam_resources ? 1 : 0
  name  = "OperationsAssumeRolePolicy"
  group = aws_iam_group.operations[0].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sts:AssumeRole"
      Effect   = "Allow"
      Resource = aws_iam_role.admin_role[0].arn
    }]
  })
}
