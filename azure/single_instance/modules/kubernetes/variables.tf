# modules/kubernetes/variables.tf

variable "enable_ingress" {
  type        = bool
  default     = false
  description = "Create an ingress on the managed NGINX (public load balancer IP)"
}

variable "env" {
  type        = string
  description = "Environment name, exposed to apps as APP_ENV"
}

variable "namespaces" {
  type        = list(string)
  description = "Namespaces to create"
  default     = []
}
