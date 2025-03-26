# File 22: modules/identity/iam.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_membership
# https://registry.terraform.io/providers/-/aws/latest/docs/resources/iam_group_policy_attachment

resource "aws_iam_user" "sre" {
  # Site Reliability Engineers
  name = "sre"
  path = "/"
  # checkov:skip=CKV_AWS_273:SSO not implemented yet, using IAM users temporarily
}

resource "aws_iam_user" "dba" {
  # Database Administrators
  name = "dba"
  path = "/"
  # checkov:skip=CKV_AWS_273:SSO not implemented yet, using IAM users temporarily
}


#trivy:ignore:AVD-AWS-0123
resource "aws_iam_group" "operations" {
  name = "operations"
  # tfsec:ignore:aws-iam-enforce-group-mfa
}

resource "aws_iam_group_membership" "operations_membership" {
  name = "operations-membership"

  users = [
    aws_iam_user.sre.name,
    aws_iam_user.dba.name,
  ]

  group = aws_iam_group.operations.name
}

resource "aws_iam_group_policy_attachment" "attach_assume_admin_policy" {
  group      = aws_iam_group.operations.name
  policy_arn = aws_iam_policy.assume_admin_role_policy.arn
}

resource "aws_iam_role" "developer_role" {
  name = "Developer"

  # The policy below allows EC2 to assume this role
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

resource "aws_iam_policy" "developer_policy" {
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
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.developer_policy.arn
}

resource "aws_iam_policy" "assume_admin_role_policy" {
  name        = "AssumeAdminRolePolicy"
  description = "Policy to allow assuming Admin role"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = aws_iam_role.admin_role.arn
      }
    ]
  })
}

#trivy:ignore:AVD-AWS-0342
resource "aws_iam_policy" "admin_policy" {
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
          aws_iam_role.ec2_role.arn,
          aws_iam_role.ecs_task_execution_role.arn,
          aws_iam_role.admin_role.arn,
          aws_iam_role.developer_role.arn,
          "arn:aws:iam::084375569056:policy/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          aws_iam_role.ec2_role.arn,
          aws_iam_role.ecs_task_execution_role.arn
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
  role       = aws_iam_role.admin_role.name
  policy_arn = aws_iam_policy.admin_policy.arn
}

resource "aws_iam_instance_profile" "operations_profile" {
  name = "operations_profile"
  role = aws_iam_role.admin_role.name
}

resource "aws_iam_group_policy" "operations_assume_role" {
  name  = "OperationsAssumeRolePolicy"
  group = aws_iam_group.operations.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sts:AssumeRole"
      Effect   = "Allow"
      Resource = aws_iam_role.admin_role.arn
    }]
  })
}
