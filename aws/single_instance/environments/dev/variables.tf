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

variable "eks_version" {
  type        = string
  default     = "1.28"
  description = "Kubernetes version for EKS"
}

variable "env" {
  type        = string
  default     = "develop"
  description = "Environment where resources are deployed"
}

variable "flow_log_bucket" {
  type        = string
  default     = ""
  description = "S3 bucket for VPC flow logs"
}

variable "flow_log_force_destroy" {
  type        = bool
  default     = false
  description = "Force destroy flow log bucket"
}

variable "instance_type" {
  type        = string
  default     = ""
  description = "AWS EC2 instance_type"
}

variable "kms_key_alias" {
  type        = string
  default     = ""
  description = "Alias for KMS key"
}

variable "kms_key_deletion_window" {
  type        = number
  default     = 7
  description = "KMS key deletion window in days"
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

variable "s3_bucket" {
  type        = string
  default     = ""
  description = "S3 bucket name"
}

variable "s3_force_destroy" {
  type        = bool
  default     = false
  description = "Force destroy S3 bucket"
}

variable "sns_topic_name" {
  type        = string
  default     = ""
  description = "SNS topic name"
}

variable "sns_custom_key_alias" {
  type        = string
  default     = ""
  description = "Alias for SNS KMS key"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.1.0.0/16"
  description = "IPv4 network address range"
}
