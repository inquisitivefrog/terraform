variable "chart_version" {
  description = "kube-prometheus-stack chart (https://prometheus-community.github.io/helm-charts)"
  type        = string
}

variable "retention" {
  description = "How long Prometheus keeps metrics"
  type        = string
  default     = "3d"
}

variable "alert_log_image" {
  description = "Image for alert-log, Alertmanager's webhook receiver (Python standard library only)"
  type        = string
  default     = "python:3.13.9-alpine3.22"
}
