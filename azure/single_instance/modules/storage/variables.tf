# modules/storage/variables.tf

variable "cmk" {
  type = object({
    key_id      = string
    identity_id = string
  })
  description = "Customer-managed key (messages-key) and the identity that uses it"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix for name uniqueness"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}
