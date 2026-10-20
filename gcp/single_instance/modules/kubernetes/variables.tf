# modules/kubernetes/variables.tf

variable "cluster_admin_users" {
  type        = map(string)
  description = "Google identities bound to cluster-admin, keyed by a short name"
  default     = {}
}

variable "enable_ingress" {
  type        = bool
  default     = false
  description = "Create an external HTTP load balancer for heartbeat-service"
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

variable "rbac_roles" {
  type = list(object({
    name       = string # short name for resource names
    user       = string # Google identity (email)
    namespace  = string
    api_groups = list(string)
    resources  = list(string)
    verbs      = list(string)
  }))
  description = "Namespace roles and the users bound to them"
  default     = []
}
