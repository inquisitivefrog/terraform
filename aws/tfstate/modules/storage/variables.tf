# File 4: modules/storage/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "dynamodb_key_arn" {
  type        = string
  description = "ARN of the DynamoDB KMS key for encryption"
}

variable "employer" {
  type        = string
  description = "Employer that owns environment deployed"
}

variable "env" {
  type        = string
  default     = "develop"
  description = "Environment where resources are deployed"
}

variable "random_suffix" {
  description = "Random suffix for S3 bucket name uniqueness"
  type        = string
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "sns_topic_logging_arn" {
  description = "ARN of the SNS topic for bucket notifications"
  type        = string
}

variable "sns_topic_logging_policy_arn" {
  type        = string
  description = "ARN of the example SNS topic logging policy"
}

variable "state_bucket_key_arn" {
  type        = string
  description = "ARN of the state bucket KMS key for encryption"
}

variable "state_log_bucket_key_arn" {
  type        = string
  description = "ARN of the state log bucket KMS key for encryption"
}

variable "tfstate_bucket" {
  type        = string
  description = "AWS S3 bucket name for storage of terraform.tfstate file"
}

