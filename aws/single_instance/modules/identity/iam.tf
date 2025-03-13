# File 22: modules/identity/iam
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
}

resource "aws_iam_user" "dba" {
  # Database Administrators
  name = "dba"
  path = "/"
}

resource "aws_iam_group" "operations" {
  name = "operations"
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

resource "aws_iam_role" "ec2_role" {
  name = "EC2Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name   = "EC2Policy"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["ssm:DescribeInstanceInformation",
                  "ssm:GetConnectionStatus"
      ]
      Effect   = "Allow"
      Resource = [
        var.public_ec2_arn,
        var.private_ec2_arn
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2Profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_policy" "developer_policy" {
  name        = "DeveloperPolicy"
  description = "Policy for developers"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "s3:List*",
          "s3:Get*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "developer_attach" {
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.developer_policy.arn
}

resource "aws_iam_role" "admin_role" {
  name = "Admin"

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

resource "aws_iam_policy" "admin_policy" {
  name        = "AdminPolicy"
  description = "Policy for administrators"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
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

resource "aws_iam_user_policy" "assume_profile" {
  name = "AssumeProfilePolicy"
  user = aws_iam_user.sre.name

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

resource "aws_iam_user_policy" "assume_role" {
  name = "AssumeRolePolicy"
  user = aws_iam_user.dba.name

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
