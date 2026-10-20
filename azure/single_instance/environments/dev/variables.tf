# azure/single_instance/environments variables

variable "aks_node_count" {
  type        = number
  default     = 2
  description = "AKS node count"
}

variable "aks_node_max_count" {
  type        = number
  default     = 3
  description = "Maximum AKS node count (3 x 2 vCPU + 2 VMs fits the 10-vCPU regional quota)"
}

variable "aks_node_vm_size" {
  type        = string
  default     = "Standard_D2als_v7"
  description = "AKS node size; smallest this subscription may use (azure/scripts/vm_sizes.sh)"
}

variable "employer" {
  type        = string
  default     = "ACME"
  description = "Employer Business Name"
}

variable "enable_ingress" {
  type        = bool
  default     = true
  description = "Managed NGINX ingress with a public load balancer IP"
}

variable "env" {
  type        = string
  description = "Environment where resources are deployed"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "my_laptop_cidr_block" {
  type        = string
  description = "Laptop public IP for SSH and the AKS API (curl -4 ifconfig.me)/32"
}

variable "pods_cidr_block" {
  type        = string
  description = "AKS overlay pod range"
}

variable "services_cidr_block" {
  type        = string
  description = "AKS service range"
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/bluedragon_azure.pub"
  description = "SSH public key for the VMs' admin user"
}

variable "subscription_id" {
  type        = string
  description = "bluedragon-sre subscription ID"
}

variable "vm_size" {
  type        = string
  default     = "Standard_F1als_v7"
  description = "Size of the public and private VMs; smallest this subscription may use"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VNet address range"
}
