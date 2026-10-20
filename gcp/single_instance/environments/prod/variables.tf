# gcp/single_instance/environments variables

variable "env" {
  type        = string
  description = "Environment where resources are deployed"
}

variable "gke_machine_type" {
  type        = string
  default     = "e2-medium"
  description = "GKE node machine type"
}

variable "gke_node_count" {
  type        = number
  default     = 2
  description = "GKE node count"
}

variable "gke_node_max_count" {
  type        = number
  default     = 3
  description = "Maximum GKE node count"
}

variable "machine_type" {
  type        = string
  default     = "e2-micro"
  description = "Machine type for the public and private VMs"
}

variable "my_laptop_cidr_block" {
  type        = string
  description = "Laptop public IP for SSH and the GKE API (curl -4 ifconfig.me)/32"
}

variable "pods_cidr_block" {
  type        = string
  description = "GKE pod range (secondary range on the private subnet)"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region where resources are deployed"
}

variable "services_cidr_block" {
  type        = string
  description = "GKE service range (secondary range on the private subnet)"
}

variable "vpc_cidr_block" {
  type        = string
  description = "IPv4 network address range"
}

variable "zones" {
  type        = list(string)
  description = "Zones in the region; the first holds the VMs, GKE and Memorystore"
}
