# File 2: variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "AWS Availability Zone within Region where resources deployed"
}

variable "ec2_keypair" {
  type        = string
  description = "AWS EC2 keypair name"
}

variable "eks_version" {
  type        = string
  default     = "1.36"
  description = "Kubernetes version for EKS"
}

variable "env" {
  type        = string
  default     = "develop"
  description = "Environment where resources are deployed"
}

variable "instance_type" {
  type        = string
  default     = ""
  description = "AWS EC2 instance_type"
  # Free-plan accounts reject other types at launch ("not eligible for Free
  # Tier"); list from describe-instance-types --filters
  # Name=free-tier-eligible,Values=true (us-east-2, 2026-10-22).
  validation {
    condition     = contains(["t3.micro", "t3.small", "t4g.micro", "t4g.small", "t8i.micro", "t8i.small", "c7i-flex.large", "m7i-flex.large"], var.instance_type)
    error_message = "Free plan account: instance_type must be Free Tier eligible (t3/t4g/t8i micro or small, c7i-flex.large, m7i-flex.large)."
  }
}

variable "my_laptop_cidr_block" {
  type        = string
  default     = ""
  description = "SSH client access IPv4 range"
}

variable "redis_port" {
  type        = number
  default     = 6379
  description = "Redis network cache port"
}

variable "region" {
  type        = string
  default     = "us-east-2"
  description = "AWS Region where resources deployed"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "IPv4 network address range"
}

variable "admin_user_name" {
  type        = string
  description = "IAM user allowed to administer the symmetric KMS key"
}

variable "eks_node_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for EKS worker nodes (separate from instance_type used by EC2/ECS)"
  # Free-plan accounts reject other types at launch ("not eligible for Free
  # Tier"); list from describe-instance-types --filters
  # Name=free-tier-eligible,Values=true (us-east-2, 2026-10-22).
  validation {
    condition     = contains(["t3.micro", "t3.small", "t4g.micro", "t4g.small", "t8i.micro", "t8i.small", "c7i-flex.large", "m7i-flex.large"], var.eks_node_instance_type)
    error_message = "Free plan account: eks_node_instance_type must be Free Tier eligible (t3/t4g/t8i micro or small, c7i-flex.large, m7i-flex.large)."
  }
}

variable "eks_node_desired_size" {
  type        = number
  default     = 3
  description = "EKS worker node count (t3.micro holds 4 pods, 2 of them system pods)"
}

variable "eks_node_max_size" {
  type        = number
  default     = 4
  description = "Maximum EKS worker node count"
}

variable "aws_account_id" {
  type        = string
  default     = "650836812595"
  description = "The only AWS account the provider may touch (Free-plan account, us-east-2 only)"
}

variable "aws_profile" {
  type        = string
  default     = "blue-elephant"
  description = "AWS CLI profile with credentials for aws_account_id"
}
