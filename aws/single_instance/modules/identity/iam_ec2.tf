# File 22: modules/identity/iam_ec2.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_membership
# https://registry.terraform.io/providers/-/aws/latest/docs/resources/iam_group_policy_attachment

resource "aws_iam_role" "ec2_role" {
  count = var.create_iam_resources ? 1: 0
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

data "aws_iam_role" "ec2_role" {
  name = "EC2Role"
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "EC2Policy"
  role = var.create_iam_resources ? aws_iam_role.ec2_role[0].id : data.aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["ssm:DescribeInstanceInformation",
        "ssm:GetConnectionStatus"
      ]
      Effect = "Allow"
      Resource = [
        var.public_ec2_arn,
        var.private_ec2_arn
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  count = var.create_iam_resources ? 1: 0
  name = "EC2Profile"
  role = var.create_iam_resources ? aws_iam_role.ec2_role[0].name : data.aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role = var.create_iam_resources ? aws_iam_role.ec2_role[0].name : data.aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
