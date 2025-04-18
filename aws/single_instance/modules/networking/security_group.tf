# File 10: modules/networking/security_group.tf

resource "aws_security_group" "elasticache" {
  name        = "cache"
  description = "Allow inbound traffic for ElastiCache"
  # checkov:skip=CKV2_AWS_5:Attached to redis-cluster in module.cache.aws_elasticache_cluster.example
  vpc_id = var.vpc_id

 ingress {
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = length(var.vpc_subnet_private_cidr_blocks) > 0 ? [var.vpc_subnet_private_cidr_blocks[0]] : [var.vpc_cidr_block]  # Fallback to VPC CIDR if empty
    description = "Allow Redis traffic from first private subnet or VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = length(var.vpc_subnet_private_cidr_blocks) > 0 ? [var.vpc_subnet_private_cidr_blocks[0]] : [var.vpc_cidr_block]  # Fallback to VPC CIDR if empty
    description = "Allow all outbound traffic to first private subnet or VPC"
  }
}

resource "aws_security_group" "private_ec2" {
  name        = "private-ec2"
  description = "Allow inbound traffic to EC2"
  # checkov:skip=CKV2_AWS_5:Attached to private-ec2 in module.compute.aws_instance.private-ec2
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_subnet_public_cidr_block] # "10.0.0.16/28"
    description = "Allow SSH from public subnet"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_subnet_public_cidr_block] # "10.0.0.16/28"
    description = "Allow ICMP (ping) from public subnet"
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow SSH outbound to VPC subnets"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow SSM Agent to reach AWS endpoints"
  }

  tags = {
    Name = "private-ec2"
  }
}

resource "aws_security_group" "public_ec2" {
  name        = "public-ec2"
  description = "Allow SSH, ICMP, HTTP, and HTTPS access"
  # checkov:skip=CKV2_AWS_5:Attached to public-ec2 in module.compute.aws_instance.public-ec2
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_laptop_cidr_block]
    description = "Allow SSH from my laptop"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.my_laptop_cidr_block]
    description = "Allow ICMP (ping) from my laptop"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_laptop_cidr_block]
    description = "Allow HTTP from my laptop"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_laptop_cidr_block]
    description = "Allow HTTPS from my laptop"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
      #"13.56.0.0/16",     # us-west-1 AWS (Ubuntu repo IPs)
      #"54.183.0.0/16",    # us-west-1 AWS (Ubuntu repo IPs)
      #"54.193.0.0/16",    # us-west-1 AWS (Ubuntu repo IPs)
      #"54.241.0.0/16",    # us-west-1 AWS (Ubuntu repo IPs)
      #"91.189.91.0/24",   # security.ubuntu.com
      #"185.125.190.0/24", # security.ubuntu.com
      #"34.107.0.0/16",    # dl.k8s.io (Google Cloud)
      #"176.32.0.0/16"     # ec2.us-west-1.amazonaws.com
    #]
    description = "Allow HTTPS to AWS EKS and Ubuntu repos"
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
      #"13.56.0.0/16",     # us-west-1 AWS (Ubuntu repo IPs)
      #"54.183.0.0/16",    # us-west-1 AWS (Ubuntu repo IPs)
      #"54.193.0.0/16",    # us-west-1 AWS (Ubuntu repo IPs)
      #"54.241.0.0/16",    # us-west-1 AWS (Ubuntu repo IPs)
      #"91.189.91.0/24",   # security.ubuntu.com
      #"185.125.190.0/24", # security.ubuntu.com
      #"34.107.0.0/16",    # dl.k8s.io (Google Cloud)
      #"176.32.0.0/16"     # ec2.us-west-1.amazonaws.com
    #]
    description = "Allow HTTP to Ubuntu repos"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      var.my_laptop_cidr_block,                     # 77.81.142.250/32
      var.vpc_subnet_public_cidr_block,             # 10.0.0.16/28
      length(var.vpc_subnet_private_cidr_blocks) > 0 ? var.vpc_subnet_private_cidr_blocks[0] : var.vpc_cidr_block  # 10.0.0.32/28
    ]
    description = "Allow all traffic to laptop and VPC subnets"
  }

  tags = {
    Name = "public-ec2"
  }
}

resource "aws_security_group" "eks_cluster" {
  name        = "eks-cluster-sg-${var.env}-${var.random_suffix}"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "eks_cluster_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.eks_cluster_sg_id
  source_security_group_id = var.sg_public_ec2_id
}
