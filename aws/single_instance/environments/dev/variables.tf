# File 2: variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "AWS Availability Zone within Region where resources deployed"
}

variable "ec2_keypair" {
  type        = string
  default     = "nobody"
  description = "AWS EC2 keypair name"
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
  default     = "us-west-2"
  description = "AWS Region where resources deployed"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.1.0.0/16"
  description = "IPv4 network address range"
}
