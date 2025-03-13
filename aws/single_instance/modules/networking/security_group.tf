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
    cidr_blocks = [var.vpc_subnet_private_cidr_block]
    description = "Allow Redis traffic from VPC subnets"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    #cidr_blocks     = ["0.0.0.0/0"] # Allow Redis clients acces to Internet
    security_groups = [aws_security_group.private_ec2.id]
    description     = "Allow all outbound traffic to VPC subnets"
  }
}

resource "aws_security_group" "private_ec2" {
  name        = "private-ec2"
  description = "Allow inbound traffic to EC2"
  vpc_id      = var.vpc_id

  # SSH access from anywhere
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
    description     = "Allow SSH from public EC2"
  }

  # ICMP (ping) from anywhere
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    security_groups = [aws_security_group.public_ec2.id]
    description = "Allow ICMP (ping) fom private VPC subnets"
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow outbound via NAT
    description = "Allow SSH outbound to VPC subnets"
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
    description = "Allow SSH from my laptop"
  }

  # ICMP (ping) from anywhere
  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    cidr_blocks = [var.my_laptop_cidr_block]
    description = "Allow ICMP (ping) from my laptop"
  }

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [var.my_laptop_cidr_block]
    description = "Allow HTTP from my laptop"
  }

  # HTTPS access from anywhere
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [var.my_laptop_cidr_block]
    description = "Allow HTTPS from my laptop"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.my_laptop_cidr_block, var.vpc_subnet_private_cidr_block, var.vpc_subnet_public_cidr_block]
    description = "Allow all outbound traffic to my laptop and VPC subnets"
  }

  tags = {
    Name = "public-ec2"
  }
}

