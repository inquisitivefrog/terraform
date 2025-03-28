# File 2: variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "employer" {
  type        = string
  default     = "ACME"
  description = "Employer Business Name"
}

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

variable "tfstate_bucket" {
  type        = string
  default     = ""
  description = "AWS S3 bucket for terraform.tfstate"
}
