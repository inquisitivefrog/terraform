variable "kube_prometheus_stack_chart_version" {
  description = "kube-prometheus-stack chart; 92.3.0 = Prometheus Operator v0.94.1"
  type        = string
  default     = "92.3.0"
}

variable "cert_manager_chart_version" {
  description = "cert-manager chart; v1.21.2 (2026-09-11)"
  type        = string
  default     = "v1.21.2"
}
