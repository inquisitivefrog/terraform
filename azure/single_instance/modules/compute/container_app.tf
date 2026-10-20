# modules/compute/container_app.tf
# Azure counterpart of aws/single_instance/modules/compute/ecs_fargate.tf
# nginx in a VNet-integrated Container Apps environment with an internal
# load balancer only (AWS: Fargate task in the private subnet, no public IP).
# Scales to zero. Logs to a capped Log Analytics workspace (AWS: Container
# Insights).

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.env}-${var.random_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.5 # caps ingestion cost
  tags                = var.tags
}

resource "azurerm_container_app_environment" "this" {
  name                           = "cae-${var.env}"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  infrastructure_subnet_id       = var.subnet_apps_id
  internal_load_balancer_enabled = true
  logs_destination               = "log-analytics"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id
  tags                           = var.tags

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_container_app" "nginx" {
  name                         = "nginx-${var.env}"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.aca_identity_id]
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "nginx"
      image  = "docker.io/library/nginx:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true # reachable across the VNet; the environment itself is internal
    target_port      = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# Internal environments need private DNS for their default domain
resource "azurerm_private_dns_zone" "apps" {
  name                = azurerm_container_app_environment.this.default_domain
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "apps" {
  name                = "*"
  private_dns_zone_id = azurerm_private_dns_zone.apps.id
  ttl                 = 300
  records             = [azurerm_container_app_environment.this.static_ip_address]
}

resource "azurerm_private_dns_zone_virtual_network_link" "apps" {
  name                = "apps-${var.env}"
  private_dns_zone_id = azurerm_private_dns_zone.apps.id
  virtual_network_id  = var.vnet_id
}
