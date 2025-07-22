# modules/networking/variables.tf
variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_route_table_ids" {
  type = list(string)
}

variable "cluster_endpoint_public_access_cidrs" {
  type = list(string)
}

variable "cluster_security_group_id" {
  type = string
}

variable "app_port" {
  type    = number
  default = 80
}
