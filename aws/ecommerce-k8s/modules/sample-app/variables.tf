# modules/sample-app/variables.tf

variable "namespace" { type = string }
variable "app_name" { type = string }
variable "image" { type = string }
variable "replicas" { type = number }
variable "port" { type = number }
variable "node_port" { type = number }
