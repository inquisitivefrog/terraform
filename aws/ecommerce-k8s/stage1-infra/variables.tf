variable "cluster_name" {
  type    = string
  default = "ecommerce-cluster"
}

variable "cluster_version" {
  type    = string
  default = "1.36"
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "cluster_endpoint_private_access" {
  type    = bool
  default = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the public EKS API, e.g. [\"<laptop IP>/32\"] (curl -4 ifconfig.me). No default: it used to be 0.0.0.0/0"
}

variable "cluster_enabled_log_types" {
  type    = list(string)
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "node_groups" {
  type = map(object({
    min_size       = number
    desired_size   = number
    max_size       = number
    instance_types = list(string)
  }))
  default = {
    default = {
      min_size       = 0
      desired_size   = 1
      max_size       = 1
      instance_types = ["t3.micro"]
    }
  }
  # Free-plan accounts reject other types at launch ("not eligible for Free
  # Tier"); same list as single_instance's instance_type validation.
  validation {
    condition = alltrue([for g in values(var.node_groups) : alltrue([
      for t in g.instance_types : contains(["t3.micro", "t3.small", "t4g.micro", "t4g.small", "t8i.micro", "t8i.small", "c7i-flex.large", "m7i-flex.large"], t)
    ])])
    error_message = "Free plan account: node group instance_types must be Free Tier eligible (t3/t4g/t8i micro or small, c7i-flex.large, m7i-flex.large)."
  }
}

variable "admin_user_arn" {
  type        = string
  description = "ARN of the IAM user granted EKS cluster admin access"
}

variable "admin_user_name" {
  type        = string
  description = "Name of the IAM user granted EKS cluster admin access"
}
