# modules/networking/nsg.tf
# Azure counterpart of aws/single_instance/modules/networking/security_group.tf
# One NSG per VM, attached to its NIC rather than the subnet: AKS nodes share
# the private subnet and need open egress. Azure's default rules allow all
# VNet and internet egress, so each NSG ends in an explicit deny (priority
# 4000), as the AWS security groups and GCP firewall rules do. Azure platform
# traffic (DNS, IMDS, the VM agent at 168.63.129.16) isn't affected.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group

# --- public VM (AWS: public-ec2) ---

resource "azurerm_network_security_group" "public_vm" {
  name                = "nsg-public-vm-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "laptop-ssh-http"
    description                = "SSH (22 and 2222, which the PIA VPN may let through), HTTP and HTTPS from my laptop"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "2222", "80", "443"]
    source_address_prefix      = var.my_laptop_cidr_block
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "laptop-icmp"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.my_laptop_cidr_block
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "web-out"
    description                = "HTTP and HTTPS out (Azure APIs, AKS, Ubuntu repos)"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                   = "internal-out"
    description            = "All traffic to laptop and VNet subnets"
    priority               = 110
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefix  = "*"
    destination_address_prefixes = [
      var.my_laptop_cidr_block,
      var.subnet_public_cidr_block,
      var.subnet_private_cidr_block,
      var.subnet_apps_cidr_block, # nginx lives here (on AWS it was in the private subnet)
    ]
  }

  security_rule {
    name                       = "deny-out"
    priority                   = 4000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# --- private VM (AWS: private-ec2) ---

resource "azurerm_network_security_group" "private_vm" {
  name                = "nsg-private-vm-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "public-subnet-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.subnet_public_cidr_block
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "public-subnet-icmp"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.subnet_public_cidr_block
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-in-vnet"
    description                = "Nothing else from inside the VNet (Azure's default allows it)"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ssh-out"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = var.vpc_cidr_block
  }

  security_rule {
    name                       = "web-out"
    description                = "HTTP and HTTPS out via the NAT gateway (Azure APIs, apt)"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "redis-out"
    description                = "Redis to the Managed Redis private endpoint"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.redis_port)
    source_address_prefix      = "*"
    destination_address_prefix = var.subnet_endpoints_cidr_block
  }

  security_rule {
    name                       = "deny-out"
    priority                   = 4000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
