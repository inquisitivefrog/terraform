variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}

variable "cluster_endpoint_private_access" {
  type = bool
}

variable "cluster_endpoint_public_access_cidrs" {
  type = list(string)
}

variable "cluster_enabled_log_types" {
  type = list(string)
}

variable "node_groups" {
  type = map(object({
    min_size       = number
    desired_size   = number
    max_size       = number
    instance_types = list(string)
  }))
}
