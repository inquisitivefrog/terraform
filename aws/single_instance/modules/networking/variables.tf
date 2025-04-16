# File 9: modules/networking/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "eks_cluster_sg_id" {
  type        = string
  description = "Security group ID for EKS cluster"
  default     = ""
}

variable "sg_public_ec2_id" {
  type        = string
  description = "Security group ID for public EC2 instance"
  default     = ""
}

variable "env" {
  type        = string
  description = "Environment name (e.g., prod, dev)"
}

variable "igw_id" {
  type        = string
  default     = ""
  description = "resource ID"
}

variable "my_laptop_cidr_block" {
  type        = string
  default     = ""
  description = "SSH access outside NAT"
}

variable "nat_id" {
  type        = string
  default     = ""
  description = "resource ID"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix for resource names"
}

variable "redis_port" {
  type        = number
  default     = 6379
  description = "Redis Port"
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "resource ID"
}

variable "vpc_cidr_block" {
  type        = string
  default     = ""
  description = "IPv4 address range"
}

variable "vpc_subnet_private_ids" {
  type        = list(string)
  default     = []
  description = "List of private subnet IDs"
}

variable "vpc_subnet_private_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "List of private subnet CIDR blocks"
}

variable "vpc_subnet_private_cidr_block" {
  type        = string
  default     = ""
  description = "Deprecated: Use vpc_subnet_private_cidr_blocks instead"
}

variable "vpc_subnet_private_id" {
  type        = string
  default     = ""
  description = "Deprecated: Use vpc_subnet_private_ids instead"
}

variable "vpc_subnet_public_cidr_block" {
  type        = string
  default     = ""
  description = "IPv4 subnet ID"
}

variable "vpc_subnet_public_id" {
  type        = string
  default     = ""
  description = "AWS vpc_subnet ID"
}
