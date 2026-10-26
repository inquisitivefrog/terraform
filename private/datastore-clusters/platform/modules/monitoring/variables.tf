variable "chart_version" {
  description = "kube-prometheus-stack chart (https://prometheus-community.github.io/helm-charts)"
  type        = string
}

variable "retention" {
  description = "How long Prometheus keeps metrics"
  type        = string
  default     = "3d"
}
