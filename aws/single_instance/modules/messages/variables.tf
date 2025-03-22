# File 4: modules/messages/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "environment" {
  description = "The environment this VPC is being deployed to"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID for tagging purposes"
  type        = string
}

variable "log_bucket_arn" {
  type        = string
  description = "ARN of the log bucket for SNS notifications"
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the developer S3 bucket"
}

variable "sns_custom_key_arn" {
  type        = string
  description = "ARN of the custom KMS key for SNS encryption"
}
