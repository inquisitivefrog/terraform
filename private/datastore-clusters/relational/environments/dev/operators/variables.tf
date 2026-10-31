variable "cnpg_chart_version" {
  description = "cloudnative-pg chart; 0.29.1 = CloudNativePG 1.30.1"
  type        = string
  default     = "0.29.1"
}

variable "barman_cloud_chart_version" {
  description = "plugin-barman-cloud chart; 0.8.1 = Barman Cloud plugin v0.15.1 (2026-09-30)"
  type        = string
  default     = "0.8.1"
}

variable "pxc_operator_chart_version" {
  description = "pxc-operator chart; 1.20.1 = Percona Operator for MySQL (PXC) 1.20.0"
  type        = string
  default     = "1.20.1"
}
