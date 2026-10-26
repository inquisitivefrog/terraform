variable "name" {
  description = "kind cluster name; the kubeconfig context is kind-<name>"
  type        = string
}

variable "node_image" {
  description = "kindest/node image, pinned by digest (the default of the kind library the provider embeds)"
  type        = string
}

variable "kubeconfig_path" {
  description = "Kubeconfig file this cluster gets to itself, so ~/.kube/config is never changed"
  type        = string
}

variable "region" {
  description = "topology.kubernetes.io/region label on every node: the data center"
  type        = string
}

variable "zones" {
  description = "One worker per zone, labelled topology.kubernetes.io/zone: the data center's independent power/cooling/network areas"
  type        = list(string)

  validation {
    condition     = length(var.zones) >= 3
    error_message = "Use at least three zones: a 3-member quorum must survive losing one."
  }
}
