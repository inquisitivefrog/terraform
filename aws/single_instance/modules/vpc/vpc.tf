# File 7: modules/vpc/vpc.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group
# https://developer.hashicorp.com/terraform/language/functions/cidrsubnet

resource "aws_vpc" "main" {
  cidr_block                           = var.vpc_cidr_block
  enable_dns_support                   = true
  enable_dns_hostnames                 = true
  enable_network_address_usage_metrics = true
  tags = {
    Name = "vpc-main"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # No ingress or egress rules = deny all traffic
  tags = {
    Name = "default-restrict-all"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 3)
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = false
  tags = {
    Name = "public"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_subnet" "private" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 4 + count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "private-${var.availability_zones[count.index]}"
  }
  depends_on = [aws_nat_gateway.nat]
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.create_iam_resources ? 1 : 0
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_role" "vpc_flow_logs" {
  count = var.create_iam_resources ? 0 : 1
  name = "vpc-flow-logs-role"
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "vpc-flow-logs-policy"
  role = var.create_iam_resources ? aws_iam_role.vpc_flow_logs[0].id : data.aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
        #[
        #  "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/vpc/flow-logs/${aws_vpc.main.id}:*"
        #]
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${aws_vpc.main.id}"
  retention_in_days = 365
  #kms_key_id        = var.vpc_flow_logs_key_id
  depends_on = [var.kms_key_resource]
}

resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = var.create_iam_resources ? aws_iam_role.vpc_flow_logs[0].arn : data.aws_iam_role.vpc_flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL" # Options: ACCEPT, REJECT, ALL
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "vpc-flow-logs"
  }
}
