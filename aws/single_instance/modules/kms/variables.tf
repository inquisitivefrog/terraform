# File 4: modules/kms/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables


variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for Flow Logs"
}
