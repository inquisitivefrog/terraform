variable "name" {
  description = "Container name; the data volume is <name>-data"
  type        = string
}

variable "image" {
  description = "SeaweedFS image (https://hub.docker.com/r/chrislusf/seaweedfs)"
  type        = string
}

variable "port" {
  description = "S3 port published on 127.0.0.1"
  type        = number
  default     = 8333
}

variable "engines" {
  description = "One bucket (<engine>-backups) and one key per engine; must match the identities in keys_dir/s3.json"
  type        = list(string)
  default     = ["pg", "mysql"]
}

variable "keys_dir" {
  description = "Absolute path of the folder holding s3.json (the S3 identities), outside the repo"
  type        = string
}
