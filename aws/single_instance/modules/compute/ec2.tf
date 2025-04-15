# modules/compute/ec2.tf
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "public-ec2" {
  # checkov:skip=CKV_AWS_88:Public IP intentional for public-facing EC2 instance
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.vpc_subnet_public_id
  key_name                    = var.ec2_keypair
  vpc_security_group_ids      = [var.sg_public_ec2_id]
  monitoring                  = true
  iam_instance_profile        = var.ec2_instance_profile_name
  ebs_optimized               = true
  associate_public_ip_address = true
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp2"
  }
  tags = {
    Name     = "ubuntu-24.04"
    Redeploy = "20250314-18"
  }
  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /home/ubuntu/.ssh
    echo "${file("~/.aws/bluedragon.pem")}" > /home/ubuntu/.ssh/bluedragon.pem
    chmod 400 /home/ubuntu/.ssh/bluedragon.pem
    chown ubuntu:ubuntu /home/ubuntu/.ssh/bluedragon.pem
    apt-get update
    apt-get install -y wget
    apt install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
    unzip terraform_1.5.7_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    apt install -y python3
    apt install -y python3-pip
    apt install -y docker.io
    usermod -aG docker ubuntu
        systemctl enable docker
    systemctl start docker
    pip3 install kubernetes==32.0.1
    pip3 install boto3
    # Optional: CloudWatch Agent
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    dpkg -i amazon-cloudwatch-agent.deb
  EOF
}

resource "aws_instance" "private-ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.vpc_subnet_private_id
  key_name                    = var.ec2_keypair
  vpc_security_group_ids      = [var.sg_private_ec2_id]
  monitoring                  = true
  iam_instance_profile        = var.ec2_instance_profile_name
  ebs_optimized               = true
  associate_public_ip_address = false
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp2"
  }
  tags = {
    Name  = "ubuntu-24.04"
    Debug = "redeploy-20250314-16"
  }
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y wget redis-tools
    wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
    dpkg -i amazon-ssm-agent.deb
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    # Optional: CloudWatch Agent
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    dpkg -i amazon-cloudwatch-agent.deb
  EOF
}
