# File 22: modules/identity/iam.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_membership
# https://registry.terraform.io/providers/-/aws/latest/docs/resources/iam_group_policy_attachment

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

data "aws_iam_user" "sre" {
  user_name = "sre"
}

data "aws_iam_user" "dba" {
  user_name = "dba"
}

data "aws_iam_group" "operations" {
  group_name = "operations"
}

resource "aws_iam_group_membership" "operations_membership" {
  name = "operations-membership"
  users = [
    var.create_iam_resources ? aws_iam_user.sre[0].name : data.aws_iam_user.sre.user_name,
    var.create_iam_resources ? aws_iam_user.dba[0].name : data.aws_iam_user.dba.user_name,
  ]
  group = var.create_iam_resources ? aws_iam_group.operations[0].name : data.aws_iam_group.operations.group_name
}

data "aws_iam_policy" "assume_admin_role_policy" {
  name = "AssumeAdminRolePolicy"
}

resource "aws_iam_group_policy_attachment" "attach_assume_admin_policy" {
  group      = var.create_iam_resources ? aws_iam_group.operations[0].name : data.aws_iam_group.operations.group_name
  policy_arn = var.create_iam_resources ? aws_iam_policy.assume_admin_role_policy[0].arn : data.aws_iam_policy.assume_admin_role_policy.arn
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
  name = "Developer"
}

data "aws_iam_policy" "developer_policy" {
  name = "DeveloperPolicy"
}

resource "aws_iam_policy" "developer_policy" {
  count       = var.create_iam_resources ? 1 : 0
  name        = "DeveloperPolicy"
  description = "Policy for developers"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:Describe*"]
        Effect   = "Allow"
        Resource = var.ec2_arns
      },
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Effect = "Allow"
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "developer_attach" {
  role       = var.create_iam_resources ? aws_iam_role.developer_role[0].name : data.aws_iam_role.developer_role.name
  policy_arn = var.create_iam_resources ? aws_iam_policy.developer_policy[0].arn : data.aws_iam_policy.developer_policy.arn
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
  name = "Admin"
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
        Resource = var.create_iam_resources ? aws_iam_role.admin_role[0].arn : data.aws_iam_role.admin_role.arn
      }
    ]
  })
}

data "aws_iam_policy" "admin_policy" {
  name = "AdminPolicy"
}

resource "aws_iam_policy" "admin_policy" {
  count       = var.create_iam_resources ? 1 : 0
  name        = "AdminPolicy"
  description = "Policy for administrators"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "elasticache:*",
          "ecs:*",
          "kms:*",
          "sns:*",
        ]
        Resource = concat(
          var.ec2_arns,
          [var.s3_bucket_arn, "${var.s3_bucket_arn}/*"],
          [var.elasticache_arn],
          [var.ecs_cluster_arn, var.ecs_service_arn],
          ["arn:aws:kms:us-west-1:084375569056:key/*"],
          var.sns_topic_arns
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
          var.create_iam_resources ? aws_iam_role.ec2_role[0].arn : data.aws_iam_role.ec2_role.arn,
          var.create_iam_resources ? aws_iam_role.ecs_task_execution_role[0].arn : data.aws_iam_role.ecs_task_execution_role.arn,
          var.create_iam_resources ? aws_iam_role.admin_role[0].arn : data.aws_iam_role.admin_role.arn,
          var.create_iam_resources ? aws_iam_role.developer_role[0].arn : data.aws_iam_role.developer_role.arn,
          "arn:aws:iam::084375569056:policy/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          var.create_iam_resources ? aws_iam_role.ec2_role[0].arn : data.aws_iam_role.ec2_role.arn,
          var.create_iam_resources ? aws_iam_role.ecs_task_execution_role[0].arn : data.aws_iam_role.ecs_task_execution_role.arn
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
  role       = var.create_iam_resources ? aws_iam_role.admin_role[0].name : data.aws_iam_role.admin_role.name
  policy_arn = var.create_iam_resources ? aws_iam_policy.admin_policy[0].arn : data.aws_iam_policy.admin_policy.arn
}

resource "aws_iam_instance_profile" "operations_profile" {
  count = var.create_iam_resources ? 1 : 0
  name  = "operations_profile"
  role  = var.create_iam_resources ? aws_iam_role.admin_role[0].name : data.aws_iam_role.admin_role.name
}

resource "aws_iam_group_policy" "operations_assume_role" {
  name  = "OperationsAssumeRolePolicy"
  group = var.create_iam_resources ? aws_iam_group.operations[0].name : data.aws_iam_group.operations.group_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sts:AssumeRole"
      Effect   = "Allow"
      Resource = var.create_iam_resources ? aws_iam_role.admin_role[0].arn : data.aws_iam_role.admin_role.arn
    }]
  })
}
