# File 2: tfstate/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "env" {
  type        = string
  default     = "develop"
  description = "Environment where resources are deployed"
}

variable "region" {
  type        = string
  default     = "us-west-1"
  description = "AWS Region where resources are deployed"
}
