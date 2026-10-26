variable "node_image" {
  description = "kindest/node image: Kubernetes v1.35.0, the default of kind v0.31.0 (embedded in provider 0.11.0)"
  type        = string
  default     = "kindest/node:v1.35.0@sha256:452d707d4862f52530247495d180205e029056831160e22870e37e3f6c1ac31f"
}

variable "kubeconfig_path" {
  description = "This cluster's own kubeconfig, outside ~/.kube/config"
  type        = string
  default     = "~/.kube/kind-datastore-dev"
}
