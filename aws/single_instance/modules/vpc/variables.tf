# File 4: modules/vpc/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "AWS Availability Zones within Region where resources deployed"
}

variable "vpc_cidr_block" {
  type        = string
  default     = ""
  description = "IPv4 address range"
}
