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
