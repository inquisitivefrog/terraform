# modules/compute/variables.tf

variable "aca_identity_id" {
  type        = string
  description = "Container app identity (AWS: ecsTaskExecutionRole)"
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Linux admin user on the VMs"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "nsg_private_vm_id" {
  type        = string
  description = "NSG for the private VM's NIC"
}

variable "nsg_public_vm_id" {
  type        = string
  description = "NSG for the public VM's NIC"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for the admin user"
}

variable "subnet_apps_id" {
  type        = string
  description = "Container Apps subnet"
}

variable "subnet_private_id" {
  type        = string
  description = "Private subnet"
}

variable "subnet_public_id" {
  type        = string
  description = "Public subnet"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}

variable "vm_identity_id" {
  type        = string
  description = "VM identity (AWS: EC2 instance profile)"
}

variable "vm_size" {
  type        = string
  description = "VM size"
}

variable "vnet_id" {
  type        = string
  description = "VNet for the Container Apps private DNS link"
}
