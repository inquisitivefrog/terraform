# File 44: ../../modules/kubernetes/variables.tf

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint"
}

variable "cluster_ca_certificate" {
  type        = string
  description = "EKS cluster CA certificate"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "rbac_roles" {
  type = list(object({
    user       = string
    namespace  = string
    api_groups = list(string)
    resources  = list(string)
    verbs      = list(string)
  }))
  description = "List of RBAC roles defining user access to namespaces"
  default     = []
}

variable "namespaces" {
  type        = list(string)
  description = "List of namespaces to create"
  default     = []
}
