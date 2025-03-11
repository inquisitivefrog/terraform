# File 13: modules/compute/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "ec2_instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 instances"
  type        = string
}
variable "ec2_keypair" {
  type        = string
  default     = ""
  description = "AWS EC2 key pair name"
}

variable "ecs_task_execution_role_arn" {
  type        = string
  default     = ""
  description = "AWS IAM Role for ECS with Fargate"
}

variable "instance_type" {
  type        = string
  default     = ""
  description = "AWS instance_type. VM footprint"
}

variable "sg_private_ec2_id" {
  type        = string
  default     = ""
  description = "aws_security_group ID"
}

variable "sg_public_ec2_id" {
  type        = string
  default     = ""
  description = "aws_security_group ID"
}

variable "vpc_subnet_private_id" {
  type        = string
  default     = ""
  description = "IPv4 subnet ID"
}

variable "vpc_subnet_public_id" {
  type        = string
  default     = ""
  description = "IPv4 subnet ID"
}
