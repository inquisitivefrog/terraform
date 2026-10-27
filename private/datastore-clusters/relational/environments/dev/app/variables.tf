variable "app_image" {
  description = "orders image; build and load it first with scripts/build_app.sh (tag = pom version)"
  type        = string
  default     = "orders:0.1.2"
}

variable "replicas" {
  description = "App pods per engine, spread across zones"
  type        = number
  default     = 2
}
