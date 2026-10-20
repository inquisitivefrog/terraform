
tim@Timothys-MacBook-Air dev % terraform apply plan-dev 
Acquiring state lock. This may take a few moments...
random_string.suffix: Creating...
random_string.suffix: Creation complete after 0s [id=kwtq7q1d]
azurerm_resource_group.this: Creating...
azurerm_resource_group.this: Still creating... [00m10s elapsed]
azurerm_resource_group.this: Still creating... [00m20s elapsed]
azurerm_resource_group.this: Creation complete after 25s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg]
module.vpc.azurerm_network_watcher.this: Creating...
module.vpc.azurerm_nat_gateway.this: Creating...
module.keyvault.azurerm_user_assigned_identity.storage: Creating...
module.keyvault.azurerm_key_vault.this: Creating...
module.cache.azurerm_private_dns_zone.redis: Creating...
module.vpc.azurerm_public_ip.nat: Creating...
module.compute.azurerm_public_ip.public_vm: Creating...
module.compute.azurerm_log_analytics_workspace.this: Creating...
module.messages.azurerm_servicebus_namespace.this: Creating...
module.cache.azurerm_managed_redis.this: Creating...
module.vpc.azurerm_network_watcher.this: Creation complete after 9s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkWatchers/nw-dev]
module.identity.azurerm_user_assigned_identity.this["developer"]: Creating...
module.compute.azurerm_public_ip.public_vm: Creation complete after 9s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/publicIPAddresses/pip-public-vm-dev]
module.identity.azurerm_user_assigned_identity.this["sre"]: Creating...
module.vpc.azurerm_public_ip.nat: Creation complete after 10s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/publicIPAddresses/pip-nat-dev]
module.identity.azurerm_user_assigned_identity.this["vm"]: Creating...
module.vpc.azurerm_nat_gateway.this: Still creating... [00m10s elapsed]
module.keyvault.azurerm_user_assigned_identity.storage: Still creating... [00m10s elapsed]
module.compute.azurerm_log_analytics_workspace.this: Still creating... [00m10s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [00m10s elapsed]
module.cache.azurerm_private_dns_zone.redis: Still creating... [00m10s elapsed]
module.messages.azurerm_servicebus_namespace.this: Still creating... [00m10s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [00m10s elapsed]
module.messages.azurerm_servicebus_namespace.this: Creation complete after 19s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ServiceBus/namespaces/sb-bluedragon-dev-kwtq7q1d]
module.identity.azurerm_user_assigned_identity.this["admin"]: Creating...
module.identity.azurerm_user_assigned_identity.this["developer"]: Still creating... [00m10s elapsed]
module.identity.azurerm_user_assigned_identity.this["sre"]: Still creating... [00m10s elapsed]
module.identity.azurerm_user_assigned_identity.this["vm"]: Still creating... [00m10s elapsed]
module.keyvault.azurerm_user_assigned_identity.storage: Still creating... [00m20s elapsed]
module.vpc.azurerm_nat_gateway.this: Still creating... [00m20s elapsed]
module.compute.azurerm_log_analytics_workspace.this: Still creating... [00m20s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [00m20s elapsed]
module.cache.azurerm_private_dns_zone.redis: Still creating... [00m20s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [00m20s elapsed]
module.vpc.azurerm_nat_gateway.this: Creation complete after 20s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/natGateways/nat-dev]
module.identity.azurerm_user_assigned_identity.this["aks"]: Creating...
module.identity.azurerm_user_assigned_identity.this["admin"]: Still creating... [00m10s elapsed]
module.identity.azurerm_user_assigned_identity.this["developer"]: Still creating... [00m20s elapsed]
module.identity.azurerm_user_assigned_identity.this["sre"]: Still creating... [00m20s elapsed]
module.identity.azurerm_user_assigned_identity.this["vm"]: Still creating... [00m20s elapsed]
module.keyvault.azurerm_user_assigned_identity.storage: Still creating... [00m30s elapsed]
module.compute.azurerm_log_analytics_workspace.this: Still creating... [00m30s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [00m30s elapsed]
module.cache.azurerm_private_dns_zone.redis: Still creating... [00m30s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [00m30s elapsed]
module.identity.azurerm_user_assigned_identity.this["aks"]: Still creating... [00m10s elapsed]
module.keyvault.azurerm_user_assigned_identity.storage: Creation complete after 34s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-storage-dev]
module.identity.azurerm_user_assigned_identity.this["dba"]: Creating...
module.cache.azurerm_private_dns_zone.redis: Creation complete after 37s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/privateDnsZones/privatelink.redis.azure.net]
module.identity.azurerm_user_assigned_identity.this["aca"]: Creating...
module.identity.azurerm_user_assigned_identity.this["admin"]: Still creating... [00m20s elapsed]
module.identity.azurerm_user_assigned_identity.this["developer"]: Still creating... [00m30s elapsed]
module.identity.azurerm_user_assigned_identity.this["sre"]: Still creating... [00m30s elapsed]
module.identity.azurerm_user_assigned_identity.this["vm"]: Still creating... [00m30s elapsed]
module.compute.azurerm_log_analytics_workspace.this: Still creating... [00m40s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [00m40s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [00m40s elapsed]
module.identity.azurerm_user_assigned_identity.this["aks"]: Still creating... [00m20s elapsed]
module.identity.azurerm_user_assigned_identity.this["sre"]: Creation complete after 32s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-sre-dev]
module.vpc.azurerm_virtual_network.main: Creating...
module.identity.azurerm_user_assigned_identity.this["developer"]: Creation complete after 32s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-developer-dev]
module.messages.azurerm_servicebus_topic.example: Creating...
module.identity.azurerm_user_assigned_identity.this["vm"]: Creation complete after 32s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-vm-dev]
module.messages.azurerm_servicebus_topic.custom: Creating...
module.identity.azurerm_user_assigned_identity.this["dba"]: Still creating... [00m10s elapsed]
module.messages.azurerm_servicebus_topic.example: Creation complete after 6s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ServiceBus/namespaces/sb-bluedragon-dev-kwtq7q1d/topics/example-topic]
module.vpc.azurerm_nat_gateway_public_ip_association.this: Creating...
module.identity.azurerm_user_assigned_identity.this["aca"]: Still creating... [00m10s elapsed]
module.messages.azurerm_servicebus_topic.custom: Creation complete after 6s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ServiceBus/namespaces/sb-bluedragon-dev-kwtq7q1d/topics/custom-topic]
module.messages.azurerm_servicebus_subscription.example: Creating...
module.vpc.azurerm_virtual_network.main: Creation complete after 7s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/virtualNetworks/vnet-main-dev]
module.messages.azurerm_servicebus_subscription.custom: Creating...
module.identity.azurerm_user_assigned_identity.this["admin"]: Still creating... [00m30s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [00m50s elapsed]
module.compute.azurerm_log_analytics_workspace.this: Still creating... [00m50s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [00m50s elapsed]
module.identity.azurerm_user_assigned_identity.this["admin"]: Creation complete after 31s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-admin-dev]
module.vpc.azurerm_subnet.apps: Creating...
module.compute.azurerm_log_analytics_workspace.this: Creation complete after 50s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.OperationalInsights/workspaces/log-dev-kwtq7q1d]
module.vpc.azurerm_subnet.public: Creating...
module.identity.azurerm_user_assigned_identity.this["aks"]: Still creating... [00m30s elapsed]
module.identity.azurerm_user_assigned_identity.this["aks"]: Creation complete after 31s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-aks-dev]
module.vpc.azurerm_subnet.private: Creating...
module.messages.azurerm_servicebus_subscription.example: Creation complete after 4s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ServiceBus/namespaces/sb-bluedragon-dev-kwtq7q1d/topics/example-topic/subscriptions/example-sub]
module.vpc.azurerm_subnet.endpoints: Creating...
module.messages.azurerm_servicebus_subscription.custom: Creation complete after 5s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ServiceBus/namespaces/sb-bluedragon-dev-kwtq7q1d/topics/custom-topic/subscriptions/custom-ordered]
module.cache.azurerm_private_dns_zone_virtual_network_link.redis: Creating...
module.identity.azurerm_user_assigned_identity.this["dba"]: Still creating... [00m20s elapsed]
module.vpc.azurerm_nat_gateway_public_ip_association.this: Still creating... [00m10s elapsed]
module.vpc.azurerm_subnet.apps: Creation complete after 7s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/virtualNetworks/vnet-main-dev/subnets/apps]
module.vpc.azurerm_subnet_nat_gateway_association.apps: Creating...
module.identity.azurerm_user_assigned_identity.this["aca"]: Still creating... [00m20s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [01m00s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [01m00s elapsed]
module.vpc.azurerm_subnet.public: Still creating... [00m10s elapsed]
module.vpc.azurerm_nat_gateway_public_ip_association.this: Creation complete after 14s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/natGateways/nat-dev|/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/publicIPAddresses/pip-nat-dev]
module.vpc.azurerm_subnet.private: Still creating... [00m10s elapsed]
module.vpc.azurerm_subnet.endpoints: Still creating... [00m10s elapsed]
module.vpc.azurerm_subnet.public: Creation complete after 13s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/virtualNetworks/vnet-main-dev/subnets/public]
module.compute.azurerm_network_interface.public_vm: Creating...
module.cache.azurerm_private_dns_zone_virtual_network_link.redis: Still creating... [00m10s elapsed]
module.identity.azurerm_user_assigned_identity.this["dba"]: Still creating... [00m30s elapsed]
module.identity.azurerm_user_assigned_identity.this["dba"]: Creation complete after 32s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-dba-dev]
module.vpc.azurerm_subnet_nat_gateway_association.apps: Still creating... [00m10s elapsed]
module.identity.azurerm_user_assigned_identity.this["aca"]: Still creating... [00m30s elapsed]
module.vpc.azurerm_subnet.private: Creation complete after 17s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/virtualNetworks/vnet-main-dev/subnets/private]
module.vpc.azurerm_subnet_nat_gateway_association.private: Creating...
module.networking.azurerm_network_security_group.public_vm: Creating...
module.identity.azurerm_user_assigned_identity.this["aca"]: Creation complete after 32s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-aca-dev]
module.identity.azurerm_role_assignment.operators_admin["dba"]: Creating...
module.identity.azurerm_role_assignment.operators_admin["sre"]: Creating...
module.keyvault.azurerm_key_vault.this: Still creating... [01m10s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [01m10s elapsed]
module.vpc.azurerm_subnet.endpoints: Still creating... [00m20s elapsed]
module.compute.azurerm_network_interface.public_vm: Still creating... [00m10s elapsed]
module.networking.azurerm_network_security_group.public_vm: Creation complete after 4s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkSecurityGroups/nsg-public-vm-dev]
module.cache.azurerm_private_dns_zone_virtual_network_link.redis: Still creating... [00m20s elapsed]
module.vpc.azurerm_subnet.endpoints: Creation complete after 24s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/virtualNetworks/vnet-main-dev/subnets/endpoints]
module.vpc.azurerm_subnet_nat_gateway_association.apps: Still creating... [00m20s elapsed]
module.vpc.azurerm_subnet_nat_gateway_association.private: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.operators_admin["sre"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.operators_admin["dba"]: Still creating... [00m10s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [01m20s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [01m20s elapsed]
module.vpc.azurerm_subnet_nat_gateway_association.apps: Creation complete after 26s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/virtualNetworks/vnet-main-dev/subnets/apps]
module.compute.azurerm_network_interface.public_vm: Still creating... [00m20s elapsed]
module.cache.azurerm_private_dns_zone_virtual_network_link.redis: Still creating... [00m30s elapsed]
module.compute.azurerm_network_interface.public_vm: Creation complete after 23s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkInterfaces/nic-public-vm-dev]
module.compute.azurerm_network_interface_security_group_association.public_vm: Creating...
module.cache.azurerm_private_dns_zone_virtual_network_link.redis: Creation complete after 35s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/privateDnsZones/privatelink.redis.azure.net/virtualNetworkLinks/redis-dev]
module.vpc.azurerm_subnet_nat_gateway_association.private: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.operators_admin["dba"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.operators_admin["sre"]: Still creating... [00m20s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [01m30s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [01m30s elapsed]
module.compute.azurerm_network_interface_security_group_association.public_vm: Creation complete after 5s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkInterfaces/nic-public-vm-dev|/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkSecurityGroups/nsg-public-vm-dev]
module.vpc.azurerm_subnet_nat_gateway_association.private: Creation complete after 25s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/virtualNetworks/vnet-main-dev/subnets/private]
module.aks.azurerm_role_assignment.subnet: Creating...
module.compute.azurerm_network_interface.private_vm: Creating...
module.identity.azurerm_role_assignment.operators_admin["sre"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.operators_admin["dba"]: Still creating... [00m30s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [01m40s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [01m40s elapsed]
module.compute.azurerm_network_interface.private_vm: Still creating... [00m10s elapsed]
module.aks.azurerm_role_assignment.subnet: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.operators_admin["dba"]: Creation complete after 35s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-admin-dev/providers/Microsoft.Authorization/roleAssignments/fa52fc2e-80cb-d071-1fb8-3fd7fb379fa2]
module.identity.azurerm_role_assignment.operators_admin["sre"]: Creation complete after 36s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-admin-dev/providers/Microsoft.Authorization/roleAssignments/a18c42a5-835a-51f8-287f-1267dff0b42e]
module.compute.azurerm_network_interface.private_vm: Creation complete after 12s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkInterfaces/nic-private-vm-dev]
module.keyvault.azurerm_key_vault.this: Still creating... [01m50s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [01m50s elapsed]
module.aks.azurerm_role_assignment.subnet: Still creating... [00m20s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [02m00s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [02m00s elapsed]
module.aks.azurerm_role_assignment.subnet: Still creating... [00m30s elapsed]
module.aks.azurerm_role_assignment.subnet: Creation complete after 33s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/virtualNetworks/vnet-main-dev/subnets/private/providers/Microsoft.Authorization/roleAssignments/aed6277f-b346-660d-3d0a-26b4f72dae71]
module.cache.azurerm_managed_redis.this: Still creating... [02m10s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [02m10s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [02m20s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [02m20s elapsed]
module.keyvault.azurerm_key_vault.this: Still creating... [02m30s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [02m30s elapsed]
module.keyvault.azurerm_key_vault.this: Creation complete after 2m34s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.KeyVault/vaults/bdsikvdevkwtq7q1d]
module.keyvault.azurerm_role_assignment.storage_key: Creating...
module.aks.azurerm_role_assignment.kms: Creating...
module.keyvault.azurerm_role_assignment.crypto_officer: Creating...
module.cache.azurerm_managed_redis.this: Still creating... [02m40s elapsed]
module.keyvault.azurerm_role_assignment.crypto_officer: Still creating... [00m10s elapsed]
module.aks.azurerm_role_assignment.kms: Still creating... [00m10s elapsed]
module.keyvault.azurerm_role_assignment.storage_key: Still creating... [00m10s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [02m50s elapsed]
module.aks.azurerm_role_assignment.kms: Still creating... [00m20s elapsed]
module.keyvault.azurerm_role_assignment.crypto_officer: Still creating... [00m20s elapsed]
module.keyvault.azurerm_role_assignment.storage_key: Still creating... [00m20s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [03m00s elapsed]
module.keyvault.azurerm_role_assignment.crypto_officer: Still creating... [00m30s elapsed]
module.keyvault.azurerm_role_assignment.storage_key: Still creating... [00m30s elapsed]
module.aks.azurerm_role_assignment.kms: Still creating... [00m30s elapsed]
module.aks.azurerm_role_assignment.kms: Creation complete after 32s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.KeyVault/vaults/bdsikvdevkwtq7q1d/providers/Microsoft.Authorization/roleAssignments/f13056c7-da08-9a53-e6f5-32d140e89a25]
module.aks.time_sleep.roles: Creating...
module.keyvault.azurerm_role_assignment.crypto_officer: Creation complete after 33s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.KeyVault/vaults/bdsikvdevkwtq7q1d/providers/Microsoft.Authorization/roleAssignments/de87cc6f-be90-ec0d-4770-39f53031e330]
module.keyvault.time_sleep.crypto_officer: Creating...
module.keyvault.azurerm_role_assignment.storage_key: Creation complete after 35s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.KeyVault/vaults/bdsikvdevkwtq7q1d/providers/Microsoft.Authorization/roleAssignments/dbd513b4-aa4a-56de-ab40-05d74ef205d2]
module.keyvault.time_sleep.storage_key: Creating...
module.cache.azurerm_managed_redis.this: Still creating... [03m10s elapsed]
module.aks.time_sleep.roles: Still creating... [00m10s elapsed]
module.keyvault.time_sleep.crypto_officer: Still creating... [00m10s elapsed]
module.keyvault.time_sleep.storage_key: Still creating... [00m10s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [03m20s elapsed]
module.aks.time_sleep.roles: Still creating... [00m20s elapsed]
module.keyvault.time_sleep.crypto_officer: Still creating... [00m20s elapsed]
module.keyvault.time_sleep.storage_key: Still creating... [00m20s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [03m30s elapsed]
module.aks.time_sleep.roles: Still creating... [00m30s elapsed]
module.keyvault.time_sleep.crypto_officer: Still creating... [00m30s elapsed]
module.keyvault.time_sleep.storage_key: Still creating... [00m30s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [03m40s elapsed]
module.aks.time_sleep.roles: Still creating... [00m40s elapsed]
module.keyvault.time_sleep.crypto_officer: Still creating... [00m40s elapsed]
module.keyvault.time_sleep.storage_key: Still creating... [00m40s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [03m50s elapsed]
module.aks.time_sleep.roles: Still creating... [00m50s elapsed]
module.keyvault.time_sleep.crypto_officer: Still creating... [00m50s elapsed]
module.keyvault.time_sleep.storage_key: Still creating... [00m50s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [04m00s elapsed]
module.aks.time_sleep.roles: Creation complete after 1m0s [id=2026-10-20T20:20:14Z]
module.keyvault.time_sleep.crypto_officer: Creation complete after 1m0s [id=2026-10-20T20:20:15Z]
module.keyvault.azurerm_key_vault_key.asymmetric: Creating...
module.keyvault.azurerm_key_vault_key.rotating["symmetric-key"]: Creating...
module.keyvault.azurerm_key_vault_key.rotating["messages-key"]: Creating...
module.keyvault.azurerm_key_vault_key.rotating["aks-kms-key"]: Creating...
module.keyvault.time_sleep.storage_key: Creation complete after 1m0s [id=2026-10-20T20:20:16Z]
module.cache.azurerm_managed_redis.this: Still creating... [04m10s elapsed]
module.keyvault.azurerm_key_vault_key.asymmetric: Creation complete after 3s [id=https://bdsikvdevkwtq7q1d.vault.azure.net/keys/asymmetric-key/783f519865d14a349c847abe28f83912]
module.keyvault.azurerm_key_vault_key.rotating["aks-kms-key"]: Creation complete after 3s [id=https://bdsikvdevkwtq7q1d.vault.azure.net/keys/aks-kms-key/fe1f12cd6cd44c4bbb0da8896330fe73]
module.aks.azurerm_kubernetes_cluster.this: Creating...
module.keyvault.azurerm_key_vault_key.rotating["symmetric-key"]: Creation complete after 3s [id=https://bdsikvdevkwtq7q1d.vault.azure.net/keys/symmetric-key/610c806196d74e5b8cec48f4e857a00c]
module.keyvault.azurerm_key_vault_key.rotating["messages-key"]: Creation complete after 4s [id=https://bdsikvdevkwtq7q1d.vault.azure.net/keys/messages-key/afeaf9c03d4c48398c500e4896fd9ae5]
module.storage.azurerm_storage_account.dev: Creating...
module.storage.azurerm_storage_account.logs: Creating...
module.cache.azurerm_managed_redis.this: Still creating... [04m20s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [00m10s elapsed]
module.storage.azurerm_storage_account.logs: Still creating... [00m10s elapsed]
module.storage.azurerm_storage_account.dev: Still creating... [00m10s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [04m30s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [00m20s elapsed]
module.storage.azurerm_storage_account.dev: Still creating... [00m20s elapsed]
module.storage.azurerm_storage_account.logs: Still creating... [00m20s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [04m40s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [00m30s elapsed]
module.storage.azurerm_storage_account.logs: Creation complete after 30s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsilogsdevkwtq7q1d]
module.storage.azurerm_storage_account.dev: Still creating... [00m30s elapsed]
module.vpc.azurerm_network_watcher_flow_log.vnet: Creating...
module.storage.azurerm_storage_management_policy.logs: Creating...
module.storage.azurerm_storage_management_policy.logs: Creation complete after 2s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsilogsdevkwtq7q1d/managementPolicies/default]
module.storage.azurerm_storage_account.dev: Creation complete after 35s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsidatadevkwtq7q1d]
module.storage.azurerm_storage_container.logs: Creating...
module.storage.azurerm_monitor_diagnostic_setting.dev_blob: Creating...
module.messages.azurerm_eventgrid_system_topic.dev_storage: Creating...
module.storage.azurerm_storage_management_policy.dev: Creating...
module.storage.azurerm_storage_management_policy.dev: Creation complete after 2s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsidatadevkwtq7q1d/managementPolicies/default]
module.cache.azurerm_managed_redis.this: Still creating... [04m50s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [00m40s elapsed]
module.vpc.azurerm_network_watcher_flow_log.vnet: Still creating... [00m10s elapsed]
module.vpc.azurerm_network_watcher_flow_log.vnet: Creation complete after 14s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkWatchers/nw-dev/flowLogs/flowlog-vnet-dev]
module.messages.azurerm_eventgrid_system_topic.dev_storage: Still creating... [00m10s elapsed]
module.storage.azurerm_storage_container.logs: Still creating... [00m10s elapsed]
module.storage.azurerm_monitor_diagnostic_setting.dev_blob: Still creating... [00m10s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [05m00s elapsed]
module.storage.azurerm_storage_container.logs: Creation complete after 13s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsidatadevkwtq7q1d/blobServices/default/containers/logs]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [00m50s elapsed]
module.messages.azurerm_eventgrid_system_topic.dev_storage: Creation complete after 15s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.EventGrid/systemTopics/evgt-dev-storage-dev]
module.messages.azurerm_role_assignment.eventgrid_sender: Creating...
module.storage.azurerm_monitor_diagnostic_setting.dev_blob: Still creating... [00m20s elapsed]
module.storage.azurerm_monitor_diagnostic_setting.dev_blob: Creation complete after 23s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsidatadevkwtq7q1d/blobServices/default|dev-access-logs]
module.cache.azurerm_managed_redis.this: Still creating... [05m10s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [01m00s elapsed]
module.messages.azurerm_role_assignment.eventgrid_sender: Still creating... [00m10s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [05m20s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [01m10s elapsed]
module.messages.azurerm_role_assignment.eventgrid_sender: Still creating... [00m20s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [05m30s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [01m20s elapsed]
module.messages.azurerm_role_assignment.eventgrid_sender: Still creating... [00m30s elapsed]
module.messages.azurerm_role_assignment.eventgrid_sender: Creation complete after 33s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ServiceBus/namespaces/sb-bluedragon-dev-kwtq7q1d/topics/example-topic/providers/Microsoft.Authorization/roleAssignments/cf02b8c4-5293-0259-acb0-4a37a4a0e86c]
module.messages.azurerm_eventgrid_system_topic_event_subscription.logs_to_example: Creating...
module.cache.azurerm_managed_redis.this: Still creating... [05m40s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [01m30s elapsed]
module.messages.azurerm_eventgrid_system_topic_event_subscription.logs_to_example: Still creating... [00m10s elapsed]
module.messages.azurerm_eventgrid_system_topic_event_subscription.logs_to_example: Creation complete after 14s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.EventGrid/systemTopics/evgt-dev-storage-dev/eventSubscriptions/logs-created]
module.cache.azurerm_managed_redis.this: Still creating... [05m50s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [01m40s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [06m00s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [01m50s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [06m10s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [02m00s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [06m20s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [02m10s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [06m30s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [02m20s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [06m40s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [02m30s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [06m50s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [02m40s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [07m00s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [02m50s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [07m10s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [03m00s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [07m20s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [03m10s elapsed]
module.cache.azurerm_managed_redis.this: Still creating... [07m30s elapsed]
module.cache.azurerm_managed_redis.this: Creation complete after 7m30s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Cache/redisEnterprise/redis-bluedragon-dev-kwtq7q1d]
module.cache.azurerm_private_endpoint.redis: Creating...
module.networking.azurerm_network_security_group.private_vm: Creating...
module.aks.azurerm_kubernetes_cluster.this: Still creating... [03m20s elapsed]
module.networking.azurerm_network_security_group.private_vm: Creation complete after 2s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkSecurityGroups/nsg-private-vm-dev]
module.compute.azurerm_network_interface_security_group_association.private_vm: Creating...
module.cache.azurerm_private_endpoint.redis: Still creating... [00m10s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [03m30s elapsed]
module.compute.azurerm_network_interface_security_group_association.private_vm: Still creating... [00m10s elapsed]
module.compute.azurerm_network_interface_security_group_association.private_vm: Creation complete after 12s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkInterfaces/nic-private-vm-dev|/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkSecurityGroups/nsg-private-vm-dev]
module.compute.azurerm_linux_virtual_machine.vm["public"]: Creating...
module.compute.azurerm_linux_virtual_machine.vm["private"]: Creating...
module.cache.azurerm_private_endpoint.redis: Still creating... [00m20s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [03m40s elapsed]
module.compute.azurerm_linux_virtual_machine.vm["private"]: Still creating... [00m10s elapsed]
module.compute.azurerm_linux_virtual_machine.vm["public"]: Still creating... [00m10s elapsed]
module.cache.azurerm_private_endpoint.redis: Still creating... [00m30s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [03m50s elapsed]
module.compute.azurerm_linux_virtual_machine.vm["public"]: Still creating... [00m20s elapsed]
module.compute.azurerm_linux_virtual_machine.vm["private"]: Still creating... [00m20s elapsed]
module.cache.azurerm_private_endpoint.redis: Still creating... [00m40s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [04m00s elapsed]
module.compute.azurerm_linux_virtual_machine.vm["public"]: Still creating... [00m30s elapsed]
module.compute.azurerm_linux_virtual_machine.vm["private"]: Still creating... [00m30s elapsed]
module.cache.azurerm_private_endpoint.redis: Still creating... [00m50s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [04m10s elapsed]
module.compute.azurerm_linux_virtual_machine.vm["private"]: Still creating... [00m40s elapsed]
module.compute.azurerm_linux_virtual_machine.vm["public"]: Still creating... [00m40s elapsed]
module.cache.azurerm_private_endpoint.redis: Still creating... [01m00s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [04m20s elapsed]
module.compute.azurerm_linux_virtual_machine.vm["private"]: Creation complete after 48s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Compute/virtualMachines/private-vm-dev]
module.compute.azurerm_linux_virtual_machine.vm["public"]: Still creating... [00m50s elapsed]
module.compute.azurerm_linux_virtual_machine.vm["public"]: Creation complete after 50s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Compute/virtualMachines/public-vm-dev]
module.cache.azurerm_private_endpoint.redis: Still creating... [01m10s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [04m30s elapsed]
module.cache.azurerm_private_endpoint.redis: Creation complete after 1m14s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/privateEndpoints/pe-redis-dev]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [04m40s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [04m50s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [05m00s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [05m10s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Still creating... [05m20s elapsed]
module.aks.azurerm_kubernetes_cluster.this: Creation complete after 5m20s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ContainerService/managedClusters/aks-dev-kwtq7q1d]
module.aks.azurerm_role_assignment.me_cluster_admin: Creating...
module.identity.azurerm_role_definition.k8s_pods_services[0]: Creating...
module.identity.azurerm_role_definition.k8s_pods_services[0]: Creation complete after 3s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/providers/Microsoft.Authorization/roleDefinitions/57e3aea7-9e43-79ab-78b4-d3cc873dfd6e|/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ContainerService/managedClusters/aks-dev-kwtq7q1d]
module.identity.azurerm_role_assignment.namespace["dba"]: Creating...
module.identity.azurerm_role_assignment.namespace["sre"]: Creating...
module.aks.azurerm_role_assignment.me_cluster_admin: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.namespace["dba"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.namespace["sre"]: Still creating... [00m10s elapsed]
module.aks.azurerm_role_assignment.me_cluster_admin: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.namespace["sre"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.namespace["dba"]: Still creating... [00m20s elapsed]
module.aks.azurerm_role_assignment.me_cluster_admin: Still creating... [00m30s elapsed]
module.aks.azurerm_role_assignment.me_cluster_admin: Creation complete after 32s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ContainerService/managedClusters/aks-dev-kwtq7q1d/providers/Microsoft.Authorization/roleAssignments/6ffef731-94c0-6d13-0957-cc6e09aabf92]
module.identity.azurerm_role_assignment.namespace["sre"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.namespace["dba"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.namespace["sre"]: Creation complete after 30s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ContainerService/managedClusters/aks-dev-kwtq7q1d/namespaces/app1/providers/Microsoft.Authorization/roleAssignments/2cbbea87-a9f3-59f0-fd50-5b55867899ce]
module.identity.azurerm_role_assignment.namespace["dba"]: Creation complete after 30s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ContainerService/managedClusters/aks-dev-kwtq7q1d/namespaces/app2/providers/Microsoft.Authorization/roleAssignments/200afebb-1c86-3dc5-27cb-b57c706e16bb]
module.kubernetes.kubernetes_namespace_v1.namespaces["app1"]: Creating...
module.kubernetes.kubernetes_namespace_v1.namespaces["app2"]: Creating...
module.kubernetes.kubernetes_namespace_v1.namespaces["app1"]: Creation complete after 1s [id=app1]
module.kubernetes.kubernetes_namespace_v1.namespaces["app2"]: Creation complete after 1s [id=app2]
module.kubernetes.kubernetes_resource_quota_v1.quota["app2"]: Creating...
module.kubernetes.kubernetes_config_map_v1.app_config["app2"]: Creating...
module.kubernetes.kubernetes_config_map_v1.app_config["app1"]: Creating...
module.kubernetes.kubernetes_resource_quota_v1.quota["app1"]: Creating...
module.kubernetes.kubernetes_secret_v1.app_secret["app1"]: Creating...
module.kubernetes.kubernetes_secret_v1.app_secret["app2"]: Creating...
module.kubernetes.kubernetes_config_map_v1.app_config["app1"]: Creation complete after 0s [id=app1/app-config]
module.kubernetes.kubernetes_secret_v1.app_secret["app2"]: Creation complete after 0s [id=app2/app-secret]
module.kubernetes.kubernetes_config_map_v1.app_config["app2"]: Creation complete after 0s [id=app2/app-config]
module.kubernetes.kubernetes_secret_v1.app_secret["app1"]: Creation complete after 0s [id=app1/app-secret]
module.kubernetes.kubernetes_deployment_v1.app["heartbeat"]: Creating...
module.kubernetes.kubernetes_deployment_v1.app["monitor"]: Creating...
module.kubernetes.kubernetes_resource_quota_v1.quota["app1"]: Creation complete after 0s [id=app1/app1-quota]
module.kubernetes.kubernetes_resource_quota_v1.quota["app2"]: Creation complete after 0s [id=app2/app2-quota]
module.kubernetes.kubernetes_deployment_v1.app["heartbeat"]: Still creating... [00m10s elapsed]
module.kubernetes.kubernetes_deployment_v1.app["monitor"]: Still creating... [00m10s elapsed]
module.kubernetes.kubernetes_deployment_v1.app["monitor"]: Still creating... [00m20s elapsed]
module.kubernetes.kubernetes_deployment_v1.app["heartbeat"]: Still creating... [00m20s elapsed]
module.kubernetes.kubernetes_deployment_v1.app["heartbeat"]: Creation complete after 26s [id=app1/heartbeat-app]
module.kubernetes.kubernetes_deployment_v1.app["monitor"]: Creation complete after 26s [id=app2/monitor-app]
module.kubernetes.kubernetes_service_v1.app["monitor"]: Creating...
module.kubernetes.kubernetes_service_v1.app["heartbeat"]: Creating...
module.kubernetes.kubernetes_service_v1.app["monitor"]: Creation complete after 0s [id=app2/monitor-service]
module.kubernetes.kubernetes_service_v1.app["heartbeat"]: Creation complete after 0s [id=app1/heartbeat-service]
module.kubernetes.kubernetes_ingress_v1.app_ingress[0]: Creating...
module.kubernetes.kubernetes_ingress_v1.app_ingress[0]: Creation complete after 0s [id=app1/app-ingress]

Error: `log_analytics_workspace_id` can only be set when `logs_destination` is set to `log-analytics` or `""`

  with module.compute.azurerm_container_app_environment.this,
  on ../../modules/compute/container_app.tf line 18, in resource "azurerm_container_app_environment" "this":
  18: resource "azurerm_container_app_environment" "this" {

Releasing state lock. This may take a few moments...
tim@Timothys-MacBook-Air dev % terraform state list
azurerm_resource_group.this
random_string.suffix
module.aks.data.azurerm_client_config.current
module.aks.azurerm_kubernetes_cluster.this
module.aks.azurerm_role_assignment.kms
module.aks.azurerm_role_assignment.me_cluster_admin
module.aks.azurerm_role_assignment.subnet
module.aks.time_sleep.roles
module.cache.azurerm_managed_redis.this
module.cache.azurerm_private_dns_zone.redis
module.cache.azurerm_private_dns_zone_virtual_network_link.redis
module.cache.azurerm_private_endpoint.redis
module.compute.azurerm_linux_virtual_machine.vm["private"]
module.compute.azurerm_linux_virtual_machine.vm["public"]
module.compute.azurerm_log_analytics_workspace.this
module.compute.azurerm_network_interface.private_vm
module.compute.azurerm_network_interface.public_vm
module.compute.azurerm_network_interface_security_group_association.private_vm
module.compute.azurerm_network_interface_security_group_association.public_vm
module.compute.azurerm_public_ip.public_vm
module.identity.azurerm_role_assignment.namespace["dba"]
module.identity.azurerm_role_assignment.namespace["sre"]
module.identity.azurerm_role_assignment.operators_admin["dba"]
module.identity.azurerm_role_assignment.operators_admin["sre"]
module.identity.azurerm_role_definition.k8s_pods_services[0]
module.identity.azurerm_user_assigned_identity.this["aca"]
module.identity.azurerm_user_assigned_identity.this["admin"]
module.identity.azurerm_user_assigned_identity.this["aks"]
module.identity.azurerm_user_assigned_identity.this["dba"]
module.identity.azurerm_user_assigned_identity.this["developer"]
module.identity.azurerm_user_assigned_identity.this["sre"]
module.identity.azurerm_user_assigned_identity.this["vm"]
module.keyvault.data.azurerm_client_config.current
module.keyvault.azurerm_key_vault.this
module.keyvault.azurerm_key_vault_key.asymmetric
module.keyvault.azurerm_key_vault_key.rotating["aks-kms-key"]
module.keyvault.azurerm_key_vault_key.rotating["messages-key"]
module.keyvault.azurerm_key_vault_key.rotating["symmetric-key"]
module.keyvault.azurerm_role_assignment.crypto_officer
module.keyvault.azurerm_role_assignment.storage_key
module.keyvault.azurerm_user_assigned_identity.storage
module.keyvault.time_sleep.crypto_officer
module.keyvault.time_sleep.storage_key
module.kubernetes.kubernetes_config_map_v1.app_config["app1"]
module.kubernetes.kubernetes_config_map_v1.app_config["app2"]
module.kubernetes.kubernetes_deployment_v1.app["heartbeat"]
module.kubernetes.kubernetes_deployment_v1.app["monitor"]
module.kubernetes.kubernetes_ingress_v1.app_ingress[0]
module.kubernetes.kubernetes_namespace_v1.namespaces["app1"]
module.kubernetes.kubernetes_namespace_v1.namespaces["app2"]
module.kubernetes.kubernetes_resource_quota_v1.quota["app1"]
module.kubernetes.kubernetes_resource_quota_v1.quota["app2"]
module.kubernetes.kubernetes_secret_v1.app_secret["app1"]
module.kubernetes.kubernetes_secret_v1.app_secret["app2"]
module.kubernetes.kubernetes_service_v1.app["heartbeat"]
module.kubernetes.kubernetes_service_v1.app["monitor"]
module.messages.azurerm_eventgrid_system_topic.dev_storage
module.messages.azurerm_eventgrid_system_topic_event_subscription.logs_to_example
module.messages.azurerm_role_assignment.eventgrid_sender
module.messages.azurerm_servicebus_namespace.this
module.messages.azurerm_servicebus_subscription.custom
module.messages.azurerm_servicebus_subscription.example
module.messages.azurerm_servicebus_topic.custom
module.messages.azurerm_servicebus_topic.example
module.networking.azurerm_network_security_group.private_vm
module.networking.azurerm_network_security_group.public_vm
module.storage.azurerm_monitor_diagnostic_setting.dev_blob
module.storage.azurerm_storage_account.dev
module.storage.azurerm_storage_account.logs
module.storage.azurerm_storage_container.logs
module.storage.azurerm_storage_management_policy.dev
module.storage.azurerm_storage_management_policy.logs
module.vpc.azurerm_nat_gateway.this
module.vpc.azurerm_nat_gateway_public_ip_association.this
module.vpc.azurerm_network_watcher.this
module.vpc.azurerm_network_watcher_flow_log.vnet
module.vpc.azurerm_public_ip.nat
module.vpc.azurerm_subnet.apps
module.vpc.azurerm_subnet.endpoints
module.vpc.azurerm_subnet.private
module.vpc.azurerm_subnet.public
module.vpc.azurerm_subnet_nat_gateway_association.apps
module.vpc.azurerm_subnet_nat_gateway_association.private
module.vpc.azurerm_virtual_network.main
tim@Timothys-MacBook-Air dev % pwd
/Users/tim/Documents/workspace/sre/terraform/azure/single_instance/environments/dev

tim@Timothys-MacBook-Air dev % terraform apply plan-dev 
Acquiring state lock. This may take a few moments...
module.compute.azurerm_container_app_environment.this: Creating...
module.vpc.azurerm_network_watcher_flow_log.vnet: Modifying... [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkWatchers/nw-dev/flowLogs/flowlog-vnet-dev]
module.storage.azurerm_storage_management_policy.logs: Modifying... [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsilogsdevkwtq7q1d/managementPolicies/default]
module.storage.azurerm_storage_management_policy.logs: Modifications complete after 2s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsilogsdevkwtq7q1d/managementPolicies/default]
module.compute.azurerm_container_app_environment.this: Still creating... [00m10s elapsed]
module.vpc.azurerm_network_watcher_flow_log.vnet: Still modifying... [id=/subscriptions/8d75b8ef-999c-4f70-99a9-...chers/nw-dev/flowLogs/flowlog-vnet-dev, 00m10s elapsed]
module.vpc.azurerm_network_watcher_flow_log.vnet: Modifications complete after 13s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkWatchers/nw-dev/flowLogs/flowlog-vnet-dev]
module.compute.azurerm_container_app_environment.this: Still creating... [00m20s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [00m30s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [00m40s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [00m50s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [01m00s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [01m10s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [01m20s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [01m30s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [01m40s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [01m50s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [02m00s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [02m10s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [02m20s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [02m30s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [02m40s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [02m50s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [03m00s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [03m10s elapsed]
module.compute.azurerm_container_app_environment.this: Still creating... [03m20s elapsed]
module.compute.azurerm_container_app_environment.this: Creation complete after 3m29s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.App/managedEnvironments/cae-dev]
module.compute.azurerm_private_dns_zone.apps: Creating...
module.compute.azurerm_container_app.nginx: Creating...
module.compute.azurerm_private_dns_zone.apps: Still creating... [00m10s elapsed]
module.compute.azurerm_container_app.nginx: Still creating... [00m10s elapsed]
module.compute.azurerm_private_dns_zone.apps: Still creating... [00m20s elapsed]
module.compute.azurerm_container_app.nginx: Still creating... [00m20s elapsed]
module.compute.azurerm_private_dns_zone.apps: Still creating... [00m30s elapsed]
module.compute.azurerm_container_app.nginx: Still creating... [00m30s elapsed]
module.compute.azurerm_private_dns_zone.apps: Creation complete after 34s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/privateDnsZones/mangomushroom-b1b34bb8.westus2.azurecontainerapps.io]
module.compute.azurerm_private_dns_zone_virtual_network_link.apps: Creating...
module.compute.azurerm_private_dns_a_record.apps: Creating...
module.compute.azurerm_private_dns_a_record.apps: Creation complete after 2s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/privateDnsZones/mangomushroom-b1b34bb8.westus2.azurecontainerapps.io/A/*]
module.compute.azurerm_container_app.nginx: Still creating... [00m40s elapsed]
module.compute.azurerm_private_dns_zone_virtual_network_link.apps: Still creating... [00m10s elapsed]
module.compute.azurerm_container_app.nginx: Still creating... [00m50s elapsed]
module.compute.azurerm_private_dns_zone_virtual_network_link.apps: Still creating... [00m20s elapsed]
module.compute.azurerm_container_app.nginx: Still creating... [01m00s elapsed]
module.compute.azurerm_private_dns_zone_virtual_network_link.apps: Still creating... [00m30s elapsed]
module.compute.azurerm_private_dns_zone_virtual_network_link.apps: Creation complete after 32s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/privateDnsZones/mangomushroom-b1b34bb8.westus2.azurecontainerapps.io/virtualNetworkLinks/apps-dev]
module.compute.azurerm_container_app.nginx: Still creating... [01m10s elapsed]
module.compute.azurerm_container_app.nginx: Still creating... [01m20s elapsed]
module.compute.azurerm_container_app.nginx: Creation complete after 1m21s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.App/containerApps/nginx-dev]
module.identity.azurerm_role_assignment.grants["developer-data"]: Creating...
module.identity.azurerm_role_assignment.grants["admin-keys"]: Creating...
module.identity.azurerm_role_assignment.grants["admin-app"]: Creating...
module.identity.azurerm_role_assignment.grants["developer-sign"]: Creating...
module.identity.azurerm_role_assignment.grants["vm-aks-admin"]: Creating...
module.identity.azurerm_role_assignment.grants["admin-data"]: Creating...
module.identity.azurerm_role_assignment.grants["developer-vm-1"]: Creating...
module.identity.azurerm_role_assignment.grants["admin-redis"]: Creating...
module.identity.azurerm_role_assignment.grants["admin-vm-1"]: Creating...
module.identity.azurerm_role_assignment.grants["developer-vm-0"]: Creating...
module.identity.azurerm_role_assignment.grants["admin-keys"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["developer-data"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["admin-data"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["developer-sign"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["admin-vm-1"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["developer-vm-0"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["vm-aks-admin"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["developer-vm-1"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["admin-app"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["admin-redis"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["vm-aks-admin"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["admin-redis"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["developer-vm-0"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["admin-app"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["developer-vm-1"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["admin-data"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["developer-data"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["developer-sign"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["admin-keys"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["admin-vm-1"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["admin-vm-1"]: Creation complete after 29s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Compute/virtualMachines/private-vm-dev/providers/Microsoft.Authorization/roleAssignments/a3b4afb9-915c-ddc1-7e59-90bc88b25370]
module.identity.azurerm_role_assignment.grants["admin-keys"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.grants["developer-vm-0"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.grants["admin-data"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.grants["vm-aks-admin"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.grants["developer-sign"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.grants["developer-data"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.grants["admin-redis"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.grants["developer-vm-1"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.grants["admin-app"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.grants["admin-redis"]: Creation complete after 30s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Cache/redisEnterprise/redis-bluedragon-dev-kwtq7q1d/providers/Microsoft.Authorization/roleAssignments/9109da77-3302-ecc4-dbe1-659c047278bf]
module.identity.azurerm_role_assignment.grants["admin-bus"]: Creating...
module.identity.azurerm_role_assignment.grants["admin-vm-0"]: Creating...
module.identity.azurerm_role_assignment.grants["developer-vm-1"]: Creation complete after 30s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Compute/virtualMachines/private-vm-dev/providers/Microsoft.Authorization/roleAssignments/35f62b01-b6a0-96b5-e2e4-6b4e1772cd7e]
module.identity.azurerm_role_assignment.grants["vm-aks-user"]: Creating...
module.identity.azurerm_role_assignment.grants["admin-app"]: Creation complete after 30s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.App/containerApps/nginx-dev/providers/Microsoft.Authorization/roleAssignments/8c4cacf4-5cd4-56f6-698c-24b090984bc7]
module.identity.azurerm_role_assignment.grants["admin-keys"]: Creation complete after 30s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.KeyVault/vaults/bdsikvdevkwtq7q1d/providers/Microsoft.Authorization/roleAssignments/1dc18f3b-dade-431d-f9f2-e378cce297bb]
module.identity.azurerm_role_assignment.grants["developer-data"]: Creation complete after 30s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsidatadevkwtq7q1d/providers/Microsoft.Authorization/roleAssignments/9c305731-5d36-36aa-e7f4-bf8ffb7f7c97]
module.identity.azurerm_role_assignment.grants["developer-vm-0"]: Creation complete after 30s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Compute/virtualMachines/public-vm-dev/providers/Microsoft.Authorization/roleAssignments/c900a994-ba02-a21a-3150-a445844053ab]
module.identity.azurerm_role_assignment.grants["vm-aks-admin"]: Creation complete after 31s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ContainerService/managedClusters/aks-dev-kwtq7q1d/providers/Microsoft.Authorization/roleAssignments/8e378a0f-0324-4749-bfb4-2ff72f0c2cd2]
module.identity.azurerm_role_assignment.grants["developer-sign"]: Creation complete after 31s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.KeyVault/vaults/bdsikvdevkwtq7q1d/keys/asymmetric-key/versions/783f519865d14a349c847abe28f83912/providers/Microsoft.Authorization/roleAssignments/5ea7d7aa-766a-1565-1edf-368bf7175b41]
module.identity.azurerm_role_assignment.grants["admin-data"]: Creation complete after 32s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsidatadevkwtq7q1d/providers/Microsoft.Authorization/roleAssignments/dd1ed235-cdf3-212c-4925-0b56dec56086]
module.identity.azurerm_role_assignment.grants["admin-bus"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["admin-vm-0"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["vm-aks-user"]: Still creating... [00m10s elapsed]
module.identity.azurerm_role_assignment.grants["admin-vm-0"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["admin-bus"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["vm-aks-user"]: Still creating... [00m20s elapsed]
module.identity.azurerm_role_assignment.grants["admin-vm-0"]: Creation complete after 29s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Compute/virtualMachines/public-vm-dev/providers/Microsoft.Authorization/roleAssignments/4dbf61f1-8021-005a-8f16-cbb4590b417a]
module.identity.azurerm_role_assignment.grants["admin-bus"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.grants["vm-aks-user"]: Still creating... [00m30s elapsed]
module.identity.azurerm_role_assignment.grants["admin-bus"]: Creation complete after 30s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ServiceBus/namespaces/sb-bluedragon-dev-kwtq7q1d/providers/Microsoft.Authorization/roleAssignments/85e72514-4a03-f666-e373-cc86a36c3078]
module.identity.azurerm_role_assignment.grants["vm-aks-user"]: Creation complete after 31s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.ContainerService/managedClusters/aks-dev-kwtq7q1d/providers/Microsoft.Authorization/roleAssignments/c534aaa1-fb19-86e6-55d3-dede2a78263f]
Releasing state lock. This may take a few moments...

Apply complete! Resources: 18 added, 2 changed, 0 destroyed.

Outputs:

aks_cluster_name = "aks-dev-kwtq7q1d"
aks_kubernetes_version = "1.36.4"
container_app_fqdn = "nginx-dev.mangomushroom-b1b34bb8.westus2.azurecontainerapps.io"
key_vault_name = "bdsikvdevkwtq7q1d"
kubeconfig_command = "az aks get-credentials --resource-group bluedragon-single-instance-dev-rg --name aks-dev-kwtq7q1d --subscription 8d75b8ef-999c-4f70-99a9-4eb0197f3a07 --admin --file ~/.kube/azure-dev"
private_vm_ip = "10.1.4.4"
public_vm_ip = "20.69.161.39"
redis_access_key = <sensitive>
redis_hostname = "redis-bluedragon-dev-kwtq7q1d.westus2.redis.azure.net"
redis_port = 10000
resource_group_name = "bluedragon-single-instance-dev-rg"
servicebus_namespace = "sb-bluedragon-dev-kwtq7q1d"
ssh_user = "azureuser"
subscription_id = "8d75b8ef-999c-4f70-99a9-4eb0197f3a07"
tim@Timothys-MacBook-Air dev % terraform state list
azurerm_resource_group.this
random_string.suffix
module.aks.data.azurerm_client_config.current
module.aks.azurerm_kubernetes_cluster.this
module.aks.azurerm_role_assignment.kms
module.aks.azurerm_role_assignment.me_cluster_admin
module.aks.azurerm_role_assignment.subnet
module.aks.time_sleep.roles
module.cache.azurerm_managed_redis.this
module.cache.azurerm_private_dns_zone.redis
module.cache.azurerm_private_dns_zone_virtual_network_link.redis
module.cache.azurerm_private_endpoint.redis
module.compute.azurerm_container_app.nginx
module.compute.azurerm_container_app_environment.this
module.compute.azurerm_linux_virtual_machine.vm["private"]
module.compute.azurerm_linux_virtual_machine.vm["public"]
module.compute.azurerm_log_analytics_workspace.this
module.compute.azurerm_network_interface.private_vm
module.compute.azurerm_network_interface.public_vm
module.compute.azurerm_network_interface_security_group_association.private_vm
module.compute.azurerm_network_interface_security_group_association.public_vm
module.compute.azurerm_private_dns_a_record.apps
module.compute.azurerm_private_dns_zone.apps
module.compute.azurerm_private_dns_zone_virtual_network_link.apps
module.compute.azurerm_public_ip.public_vm
module.identity.azurerm_role_assignment.grants["admin-app"]
module.identity.azurerm_role_assignment.grants["admin-bus"]
module.identity.azurerm_role_assignment.grants["admin-data"]
module.identity.azurerm_role_assignment.grants["admin-keys"]
module.identity.azurerm_role_assignment.grants["admin-redis"]
module.identity.azurerm_role_assignment.grants["admin-vm-0"]
module.identity.azurerm_role_assignment.grants["admin-vm-1"]
module.identity.azurerm_role_assignment.grants["developer-data"]
module.identity.azurerm_role_assignment.grants["developer-sign"]
module.identity.azurerm_role_assignment.grants["developer-vm-0"]
module.identity.azurerm_role_assignment.grants["developer-vm-1"]
module.identity.azurerm_role_assignment.grants["vm-aks-admin"]
module.identity.azurerm_role_assignment.grants["vm-aks-user"]
module.identity.azurerm_role_assignment.namespace["dba"]
module.identity.azurerm_role_assignment.namespace["sre"]
module.identity.azurerm_role_assignment.operators_admin["dba"]
module.identity.azurerm_role_assignment.operators_admin["sre"]
module.identity.azurerm_role_definition.k8s_pods_services[0]
module.identity.azurerm_user_assigned_identity.this["aca"]
module.identity.azurerm_user_assigned_identity.this["admin"]
module.identity.azurerm_user_assigned_identity.this["aks"]
module.identity.azurerm_user_assigned_identity.this["dba"]
module.identity.azurerm_user_assigned_identity.this["developer"]
module.identity.azurerm_user_assigned_identity.this["sre"]
module.identity.azurerm_user_assigned_identity.this["vm"]
module.keyvault.data.azurerm_client_config.current
module.keyvault.azurerm_key_vault.this
module.keyvault.azurerm_key_vault_key.asymmetric
module.keyvault.azurerm_key_vault_key.rotating["aks-kms-key"]
module.keyvault.azurerm_key_vault_key.rotating["messages-key"]
module.keyvault.azurerm_key_vault_key.rotating["symmetric-key"]
module.keyvault.azurerm_role_assignment.crypto_officer
module.keyvault.azurerm_role_assignment.storage_key
module.keyvault.azurerm_user_assigned_identity.storage
module.keyvault.time_sleep.crypto_officer
module.keyvault.time_sleep.storage_key
module.kubernetes.kubernetes_config_map_v1.app_config["app1"]
module.kubernetes.kubernetes_config_map_v1.app_config["app2"]
module.kubernetes.kubernetes_deployment_v1.app["heartbeat"]
module.kubernetes.kubernetes_deployment_v1.app["monitor"]
module.kubernetes.kubernetes_ingress_v1.app_ingress[0]
module.kubernetes.kubernetes_namespace_v1.namespaces["app1"]
module.kubernetes.kubernetes_namespace_v1.namespaces["app2"]
module.kubernetes.kubernetes_resource_quota_v1.quota["app1"]
module.kubernetes.kubernetes_resource_quota_v1.quota["app2"]
module.kubernetes.kubernetes_secret_v1.app_secret["app1"]
module.kubernetes.kubernetes_secret_v1.app_secret["app2"]
module.kubernetes.kubernetes_service_v1.app["heartbeat"]
module.kubernetes.kubernetes_service_v1.app["monitor"]
module.messages.azurerm_eventgrid_system_topic.dev_storage
module.messages.azurerm_eventgrid_system_topic_event_subscription.logs_to_example
module.messages.azurerm_role_assignment.eventgrid_sender
module.messages.azurerm_servicebus_namespace.this
module.messages.azurerm_servicebus_subscription.custom
module.messages.azurerm_servicebus_subscription.example
module.messages.azurerm_servicebus_topic.custom
module.messages.azurerm_servicebus_topic.example
module.networking.azurerm_network_security_group.private_vm
module.networking.azurerm_network_security_group.public_vm
module.storage.azurerm_monitor_diagnostic_setting.dev_blob
module.storage.azurerm_storage_account.dev
module.storage.azurerm_storage_account.logs
module.storage.azurerm_storage_container.logs
module.storage.azurerm_storage_management_policy.dev
module.storage.azurerm_storage_management_policy.logs
module.vpc.azurerm_nat_gateway.this
module.vpc.azurerm_nat_gateway_public_ip_association.this
module.vpc.azurerm_network_watcher.this
module.vpc.azurerm_network_watcher_flow_log.vnet
module.vpc.azurerm_public_ip.nat
module.vpc.azurerm_subnet.apps
module.vpc.azurerm_subnet.endpoints
module.vpc.azurerm_subnet.private
module.vpc.azurerm_subnet.public
module.vpc.azurerm_subnet_nat_gateway_association.apps
module.vpc.azurerm_subnet_nat_gateway_association.private
module.vpc.azurerm_virtual_network.main
tim@Timothys-MacBook-Air dev % 

tim@Timothys-MacBook-Air terraform % cd azure/single_instance/environments/dev 
tim@Timothys-MacBook-Air dev % terraform apply plan-dev
Acquiring state lock. This may take a few moments...
module.storage.azurerm_role_assignment.me_read["logs"]: Creating...
module.storage.azurerm_role_assignment.me_read["dev"]: Creating...
module.networking.azurerm_network_security_group.public_vm: Modifying... [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkSecurityGroups/nsg-public-vm-dev]
module.networking.azurerm_network_security_group.public_vm: Modifications complete after 2s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Network/networkSecurityGroups/nsg-public-vm-dev]
module.storage.azurerm_role_assignment.me_read["dev"]: Still creating... [00m10s elapsed]
module.storage.azurerm_role_assignment.me_read["logs"]: Still creating... [00m10s elapsed]
module.storage.azurerm_role_assignment.me_read["dev"]: Still creating... [00m20s elapsed]
module.storage.azurerm_role_assignment.me_read["logs"]: Still creating... [00m20s elapsed]
module.storage.azurerm_role_assignment.me_read["dev"]: Creation complete after 29s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsidatadevkwtq7q1d/providers/Microsoft.Authorization/roleAssignments/25d3841f-3ecf-402e-9a79-93eac9542ee3]
module.storage.azurerm_role_assignment.me_read["logs"]: Still creating... [00m30s elapsed]
module.storage.azurerm_role_assignment.me_read["logs"]: Creation complete after 32s [id=/subscriptions/8d75b8ef-999c-4f70-99a9-4eb0197f3a07/resourceGroups/bluedragon-single-instance-dev-rg/providers/Microsoft.Storage/storageAccounts/bdsilogsdevkwtq7q1d/providers/Microsoft.Authorization/roleAssignments/099aa93c-ec54-c5cf-d8b6-b03944661e1b]
Releasing state lock. This may take a few moments...

Apply complete! Resources: 2 added, 1 changed, 0 destroyed.

Outputs:

aks_cluster_name = "aks-dev-kwtq7q1d"
aks_kubernetes_version = "1.36.4"
container_app_fqdn = "nginx-dev.mangomushroom-b1b34bb8.westus2.azurecontainerapps.io"
key_vault_name = "bdsikvdevkwtq7q1d"
kubeconfig_command = "az aks get-credentials --resource-group bluedragon-single-instance-dev-rg --name aks-dev-kwtq7q1d --subscription 8d75b8ef-999c-4f70-99a9-4eb0197f3a07 --admin --file ~/.kube/azure-dev"
private_vm_ip = "10.1.4.4"
public_vm_ip = "20.69.161.39"
redis_access_key = <sensitive>
redis_hostname = "redis-bluedragon-dev-kwtq7q1d.westus2.redis.azure.net"
redis_port = 10000
resource_group_name = "bluedragon-single-instance-dev-rg"
servicebus_namespace = "sb-bluedragon-dev-kwtq7q1d"
ssh_user = "azureuser"
subscription_id = "8d75b8ef-999c-4f70-99a9-4eb0197f3a07"
tim@Timothys-MacBook-Air dev % terraform state list
azurerm_resource_group.this
random_string.suffix
module.aks.data.azurerm_client_config.current
module.aks.azurerm_kubernetes_cluster.this
module.aks.azurerm_role_assignment.kms
module.aks.azurerm_role_assignment.me_cluster_admin
module.aks.azurerm_role_assignment.subnet
module.aks.time_sleep.roles
module.cache.azurerm_managed_redis.this
module.cache.azurerm_private_dns_zone.redis
module.cache.azurerm_private_dns_zone_virtual_network_link.redis
module.cache.azurerm_private_endpoint.redis
module.compute.azurerm_container_app.nginx
module.compute.azurerm_container_app_environment.this
module.compute.azurerm_linux_virtual_machine.vm["private"]
module.compute.azurerm_linux_virtual_machine.vm["public"]
module.compute.azurerm_log_analytics_workspace.this
module.compute.azurerm_network_interface.private_vm
module.compute.azurerm_network_interface.public_vm
module.compute.azurerm_network_interface_security_group_association.private_vm
module.compute.azurerm_network_interface_security_group_association.public_vm
module.compute.azurerm_private_dns_a_record.apps
module.compute.azurerm_private_dns_zone.apps
module.compute.azurerm_private_dns_zone_virtual_network_link.apps
module.compute.azurerm_public_ip.public_vm
module.identity.azurerm_role_assignment.grants["admin-app"]
module.identity.azurerm_role_assignment.grants["admin-bus"]
module.identity.azurerm_role_assignment.grants["admin-data"]
module.identity.azurerm_role_assignment.grants["admin-keys"]
module.identity.azurerm_role_assignment.grants["admin-redis"]
module.identity.azurerm_role_assignment.grants["admin-vm-0"]
module.identity.azurerm_role_assignment.grants["admin-vm-1"]
module.identity.azurerm_role_assignment.grants["developer-data"]
module.identity.azurerm_role_assignment.grants["developer-sign"]
module.identity.azurerm_role_assignment.grants["developer-vm-0"]
module.identity.azurerm_role_assignment.grants["developer-vm-1"]
module.identity.azurerm_role_assignment.grants["vm-aks-admin"]
module.identity.azurerm_role_assignment.grants["vm-aks-user"]
module.identity.azurerm_role_assignment.namespace["dba"]
module.identity.azurerm_role_assignment.namespace["sre"]
module.identity.azurerm_role_assignment.operators_admin["dba"]
module.identity.azurerm_role_assignment.operators_admin["sre"]
module.identity.azurerm_role_definition.k8s_pods_services[0]
module.identity.azurerm_user_assigned_identity.this["aca"]
module.identity.azurerm_user_assigned_identity.this["admin"]
module.identity.azurerm_user_assigned_identity.this["aks"]
module.identity.azurerm_user_assigned_identity.this["dba"]
module.identity.azurerm_user_assigned_identity.this["developer"]
module.identity.azurerm_user_assigned_identity.this["sre"]
module.identity.azurerm_user_assigned_identity.this["vm"]
module.keyvault.data.azurerm_client_config.current
module.keyvault.azurerm_key_vault.this
module.keyvault.azurerm_key_vault_key.asymmetric
module.keyvault.azurerm_key_vault_key.rotating["aks-kms-key"]
module.keyvault.azurerm_key_vault_key.rotating["messages-key"]
module.keyvault.azurerm_key_vault_key.rotating["symmetric-key"]
module.keyvault.azurerm_role_assignment.crypto_officer
module.keyvault.azurerm_role_assignment.storage_key
module.keyvault.azurerm_user_assigned_identity.storage
module.keyvault.time_sleep.crypto_officer
module.keyvault.time_sleep.storage_key
module.kubernetes.kubernetes_config_map_v1.app_config["app1"]
module.kubernetes.kubernetes_config_map_v1.app_config["app2"]
module.kubernetes.kubernetes_deployment_v1.app["heartbeat"]
module.kubernetes.kubernetes_deployment_v1.app["monitor"]
module.kubernetes.kubernetes_ingress_v1.app_ingress[0]
module.kubernetes.kubernetes_namespace_v1.namespaces["app1"]
module.kubernetes.kubernetes_namespace_v1.namespaces["app2"]
module.kubernetes.kubernetes_resource_quota_v1.quota["app1"]
module.kubernetes.kubernetes_resource_quota_v1.quota["app2"]
module.kubernetes.kubernetes_secret_v1.app_secret["app1"]
module.kubernetes.kubernetes_secret_v1.app_secret["app2"]
module.kubernetes.kubernetes_service_v1.app["heartbeat"]
module.kubernetes.kubernetes_service_v1.app["monitor"]
module.messages.azurerm_eventgrid_system_topic.dev_storage
module.messages.azurerm_eventgrid_system_topic_event_subscription.logs_to_example
module.messages.azurerm_role_assignment.eventgrid_sender
module.messages.azurerm_servicebus_namespace.this
module.messages.azurerm_servicebus_subscription.custom
module.messages.azurerm_servicebus_subscription.example
module.messages.azurerm_servicebus_topic.custom
module.messages.azurerm_servicebus_topic.example
module.networking.azurerm_network_security_group.private_vm
module.networking.azurerm_network_security_group.public_vm
module.storage.data.azurerm_client_config.current
module.storage.azurerm_monitor_diagnostic_setting.dev_blob
module.storage.azurerm_role_assignment.me_read["dev"]
module.storage.azurerm_role_assignment.me_read["logs"]
module.storage.azurerm_storage_account.dev
module.storage.azurerm_storage_account.logs
module.storage.azurerm_storage_container.logs
module.storage.azurerm_storage_management_policy.dev
module.storage.azurerm_storage_management_policy.logs
module.vpc.azurerm_nat_gateway.this
module.vpc.azurerm_nat_gateway_public_ip_association.this
module.vpc.azurerm_network_watcher.this
module.vpc.azurerm_network_watcher_flow_log.vnet
module.vpc.azurerm_public_ip.nat
module.vpc.azurerm_subnet.apps
module.vpc.azurerm_subnet.endpoints
module.vpc.azurerm_subnet.private
module.vpc.azurerm_subnet.public
module.vpc.azurerm_subnet_nat_gateway_association.apps
module.vpc.azurerm_subnet_nat_gateway_association.private
module.vpc.azurerm_virtual_network.main
tim@Timothys-MacBook-Air dev % 

