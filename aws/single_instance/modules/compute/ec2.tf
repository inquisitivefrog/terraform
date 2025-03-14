# File 14: modules/compute/ec2.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance.html

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "public-ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.vpc_subnet_public_id
  key_name                    = var.ec2_keypair # AWS key pair name
  vpc_security_group_ids      = [var.sg_public_ec2_id]
  monitoring                  = true
  iam_instance_profile        = var.ec2_instance_profile_name 
  ebs_optimized               = true
  associate_public_ip_address = false
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # Forces IMDSv2
  }
  root_block_device {
    encrypted = true
    volume_size = 8
    volume_type = "gp2"
  }
  tags = {
    Name = "ubuntu-24.04"
  }
  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /home/ubuntu/.ssh
    echo "${file("~/.aws/bluedragon.pem")}" > /home/ubuntu/.ssh/bluedragon.pem
    chmod 400 /home/ubuntu/.ssh/bluedragon.pem
    chown ubuntu:ubuntu /home/ubuntu/.ssh/bluedragon.pem
    apt-get update
    apt-get install -y amazon-cloudwatch-agent
    apt-get install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
}

resource "aws_instance" "private-ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.vpc_subnet_private_id
  key_name                    = var.ec2_keypair # AWS key pair name
  vpc_security_group_ids      = [var.sg_private_ec2_id]
  monitoring                  = true
  iam_instance_profile        = var.ec2_instance_profile_name 
  ebs_optimized               = true
  associate_public_ip_address = false
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    encrypted = true
    volume_size = 8
    volume_type = "gp2"
  }
  tags = {
    Name = "ubuntu-24.04"
  }
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y amazon-cloudwatch-agent
    apt-get install -y redis-tools
    apt-get install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
}

