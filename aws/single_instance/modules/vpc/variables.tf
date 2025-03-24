# File 4: modules/vpc/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "AWS Availability Zones within Region where resources deployed"
}

variable "kms_key_resource" {
  description = "The KMS key resource for VPC Flow Logs encryption"
  type        = any
}

variable "region" {
  type        = string
  default     = "us-west-1"
  description = "AWS Region where resources deployed"
}

variable "vpc_cidr_block" {
  type        = string
  default     = ""
  description = "IPv4 address range"
}

variable "vpc_flow_logs_key_arn" {
  type        = string
  description = "ARN of the KMS key for VPC Flow Logs encryption"
}

variable "vpc_flow_logs_key_id" {
  type        = string
  description = "ID of the KMS key for VPC Flow Logs encryption"
}
