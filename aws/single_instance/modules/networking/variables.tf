# File 9: modules/networking/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

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

variable "vpc_subnet_private_cidr_block" {
  type        = string
  default     = ""
  description = "IPv4 subnet ID"
}

variable "vpc_subnet_private_id" {
  type        = string
  default     = ""
  description = "AWS vpc_subnet ID"
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

