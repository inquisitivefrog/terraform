# File 10: modules/networking/security_group.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group.html

resource "aws_security_group" "elasticache" {
  name        = "cache"
  description = "Allow inbound traffic for ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_subnet_private_cidr_block, var.vpc_subnet_public_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_subnet_private_cidr_block, var.vpc_subnet_public_cidr_block]
  }
}

resource "aws_security_group" "private_ec2" {
  name        = "private-ec2"
  description = "Allow inbound traffic to EC2"
  vpc_id      = var.vpc_id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_subnet_private_cidr_block, var.vpc_subnet_public_cidr_block]
  }

  # ICMP (ping) from anywhere
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_subnet_private_cidr_block, var.vpc_subnet_public_cidr_block]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_subnet_private_cidr_block, var.vpc_subnet_public_cidr_block]
  }

  tags = {
    Name = "private-ec2"
  }
}

resource "aws_security_group" "public_ec2" {
  name        = "public-ec2"
  description = "Allow SSH, ICMP, HTTP, and HTTPS access"
  vpc_id      = var.vpc_id

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [var.my_laptop_cidr_block]
  }

  # ICMP (ping) from anywhere
  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    cidr_blocks = [var.my_laptop_cidr_block]
  }

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [var.my_laptop_cidr_block]
  }

  # HTTPS access from anywhere
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [var.my_laptop_cidr_block]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = [var.my_laptop_cidr_block, var.vpc_subnet_private_cidr_block, var.vpc_subnet_public_cidr_block]
  }

  tags = {
    Name = "public-ec2"
  }
}

