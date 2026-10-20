# azure/tfstate/environments variables

variable "employer" {
  type        = string
  default     = "ACME"
  description = "Employer Business Name"
}

variable "env" {
  type        = string
  description = "Environment where resources are deployed"
}

variable "location" {
  type        = string
  description = "Azure region where resources are deployed"
}

variable "subscription_id" {
  type        = string
  description = "bluedragon-sre subscription ID"
}
