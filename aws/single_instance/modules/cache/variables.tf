# File 16: modules/cache/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "redis_port" {
  type        = number
  default     = 6379
  description = "Redis Port"
}

variable "sg_elasticache_id" {
  type        = string
  default     = ""
  description = "aws_security_group ID"
}

variable "vpc_subnet_private_id" {
  type        = string
  default     = ""
  description = "AWS vpc_subnet ID"
}

variable "vpc_subnet_public_id" {
  type        = string
  default     = ""
  description = "AWS vpc_subnet ID"
}

