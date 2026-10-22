# File 2: tfstate/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "env" {
  type        = string
  default     = "develop"
  description = "Environment where resources are deployed"
}

variable "region" {
  type        = string
  default     = "us-east-2"
  description = "AWS Region where resources are deployed"
}

variable "aws_account_id" {
  type        = string
  default     = "650836812595"
  description = "The only AWS account the provider may touch (Free-plan account, us-east-2 only)"
}

variable "aws_profile" {
  type        = string
  default     = "blue-elephant"
  description = "AWS CLI profile with credentials for aws_account_id"
}
