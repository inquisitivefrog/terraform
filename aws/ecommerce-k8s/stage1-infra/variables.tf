variable "cluster_name" {
  type    = string
  default = "ecommerce-cluster"
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_endpoint_private_access" {
  type    = bool
  default = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
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
}

variable "admin_user_arn" {
  type    = string
  default = "arn:aws:iam::084375569056:user/bluedragon"
}

variable "admin_user_name" {
  type    = string
  default = "bluedragon"
}
