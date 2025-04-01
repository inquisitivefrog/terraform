# File 4: modules/kms/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables


variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "env" {
  type = string
  description = "environment: prod, dev"
}

variable "region" {
  type        = string
  description = "AWS Region"
}
