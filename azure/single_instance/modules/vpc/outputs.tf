# modules/vpc/outputs.tf

output "nat_public_ip" {
  value = azurerm_public_ip.nat.ip_address
}

output "subnet_apps_cidr_block" {
  value = azurerm_subnet.apps.address_prefixes[0]
}

output "subnet_apps_id" {
  value = azurerm_subnet.apps.id
}

output "subnet_endpoints_cidr_block" {
  value = azurerm_subnet.endpoints.address_prefixes[0]
}

output "subnet_endpoints_id" {
  value = azurerm_subnet.endpoints.id
}

output "subnet_private_cidr_block" {
  value = azurerm_subnet.private.address_prefixes[0]
}

output "subnet_private_id" {
  value = azurerm_subnet.private.id
  # AKS nodes reach the API server only through the NAT gateway. Waiting on
  # both associations also makes destroy remove AKS (and the Kubernetes
  # resources) before the NAT loses its public IP; otherwise the nodes go
  # NotReady, pods hang in Terminating and namespace deletion never finishes.
  depends_on = [
    azurerm_subnet_nat_gateway_association.private,
    azurerm_nat_gateway_public_ip_association.this,
  ]
}

output "subnet_public_cidr_block" {
  value = azurerm_subnet.public.address_prefixes[0]
}

output "subnet_public_id" {
  value = azurerm_subnet.public.id
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}
