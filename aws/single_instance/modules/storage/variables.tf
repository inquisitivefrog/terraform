# File 4: modules/storage/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "random_suffix" {
  description = "Random suffix for S3 bucket name uniqueness"
  type        = string
}

variable "sns_custom_key_arn" {
  type        = string
  description = "ARN of the custom KMS key for encryption"
}

variable "sns_topic_example_arn" {
  description = "ARN of the SNS topic for bucket notifications"
  type        = string
}

variable "sns_topic_example_policy_arn" {
  type        = string
  description = "ARN of the example SNS topic policy"
}
