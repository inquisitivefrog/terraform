variable "cluster_endpoint" {
  type = string
}
variable "cluster_ca_data" {
  type = string
}
variable "cluster_name" {
  type = string
}
variable "region" {
  type = string
}
variable "helm_release_name" {
  type = string
}
variable "helm_repository" {
  type    = string
  default = ""
}
variable "helm_chart" {
  type = string
}
variable "helm_version" {
  type    = string
  default = ""
}
variable "namespace" {
  type = string
}
variable "create_namespace" {
  type    = bool
  default = true
}
variable "values" {
  type    = map(string)
  default = {}
}
variable "alb_controller_release" {
  type    = any
  default = null
}
