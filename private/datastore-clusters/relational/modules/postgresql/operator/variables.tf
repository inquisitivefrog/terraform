variable "chart_version" {
  description = "Operator Helm chart version"
  type        = string
}

variable "barman_cloud_chart_version" {
  description = "plugin-barman-cloud Helm chart version (needs cert-manager)"
  type        = string
}
