# File 4: modules/kms/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "env" {
  type        = string
  description = "environment: prod, dev"
}
