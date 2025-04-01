# File 4: modules/storage/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "employer" {
  description = "Employer that owns environment deployed"
  type        = string
}

variable "enable_notifications" {
  type        = bool
  default     = false
  description = "Enable S3 bucket notifications to SNS"
}

variable "env" {
  default     = "develop"
  description = "Environment where resources are deployed"
  type        = string
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
  default     = ""
  description = "ARN of the SNS topic for bucket notifications"
  type        = string
}

variable "sns_topic_logging_policy_arn" {
  default     = ""
  description = "ARN of the example SNS topic logging policy"
  type        = string
}

variable "state_bucket_key_arn" {
  description = "ARN of the state bucket KMS key for encryption"
  type        = string
}

variable "state_log_bucket_key_arn" {
  description = "ARN of the state log bucket KMS key for encryption"
  type        = string
}

variable "tfstate_bucket" {
  description = "AWS S3 bucket name for storage of terraform.tfstate file"
  type        = string
}
