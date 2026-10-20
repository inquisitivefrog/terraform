variable "subscription_id" {
  type        = string
  description = "bluedragon-sre subscription ID"
}

variable "budget_amount" {
  type        = number
  default     = 25
  description = "Monthly budget alert for the whole bluedragon-sre subscription, USD"
}

variable "budget_email" {
  type        = string
  description = "Where budget alerts go"
}

