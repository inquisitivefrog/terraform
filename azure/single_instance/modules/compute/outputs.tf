# modules/compute/outputs.tf

output "admin_username" {
  value = var.admin_username
}

output "container_app_fqdn" {
  value = azurerm_container_app.nginx.ingress[0].fqdn
}

output "container_app_id" {
  value = azurerm_container_app.nginx.id
}

output "private_vm_ip" {
  value = azurerm_network_interface.private_vm.private_ip_address
}

output "public_vm_ip" {
  value = azurerm_public_ip.public_vm.ip_address
}

output "vm_ids" {
  value = [for k in ["public", "private"] : azurerm_linux_virtual_machine.vm[k].id]
}

output "vm_names" {
  value = { for k, v in azurerm_linux_virtual_machine.vm : k => v.name }
}
