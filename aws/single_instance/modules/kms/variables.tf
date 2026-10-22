# File 4: modules/kms/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "env" {
  type        = string
  description = "Environment name; keeps regional resource names unique when dev and prod share a region"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "admin_user_name" {
  type        = string
  description = "IAM user allowed to administer the symmetric KMS key"
}

variable "region" {
  type        = string
  description = "AWS Region"
}

