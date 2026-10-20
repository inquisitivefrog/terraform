# modules/networking/outputs.tf

output "nsg_private_vm_id" {
  value = azurerm_network_security_group.private_vm.id
}

output "nsg_public_vm_id" {
  value = azurerm_network_security_group.public_vm.id
}
