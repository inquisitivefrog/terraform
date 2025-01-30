# File 7: modules/vpc/vpc.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group
# https://developer.hashicorp.com/terraform/language/functions/cidrsubnet

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-main"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 12, 1)
  #cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "public"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 12, 2)
  #cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = false
  tags = {
    Name = "private"
  }
  depends_on = [aws_nat_gateway.nat]
}
