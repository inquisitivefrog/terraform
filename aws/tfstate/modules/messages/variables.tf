# File 4: modules/messages/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "account_id" {
  description = "AWS Account ID for tagging purposes"
  type        = string
}

variable "environment" {
  description = "The environment this VPC is being deployed to"
  type        = string
}

variable "random_suffix" {
  description = "Random suffix for S3 bucket name uniqueness"
  type        = string
}

variable "sns_logging_key_arn" {
  type        = string
  description = "ARN of the custom KMS key for SNS encryption"
}

variable "tfstate_bucket" {
  type        = string
  description = "AWS S3 bucket name for storage of terraform.tfstate file"
}
