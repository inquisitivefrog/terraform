# modules/compute/vm.tf
# Azure counterpart of aws/single_instance/modules/compute/ec2.tf
# Ubuntu 24.04 with Trusted Launch. SSH with your key (personal Microsoft
# accounts can't use Entra ID SSH login); no private key is stored on the
# VMs, so reach the private VM through the public one with ssh -J. The
# public VM's sshd also listens on 2222 in case the PIA VPN drops port 22.
# cloud-init runs user data once per VM, so no "already done" marker.

locals {
  ubuntu = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  public_init = <<-EOF
    #!/bin/bash
    set -e
    printf 'Port 22\nPort 2222\n' > /etc/ssh/sshd_config.d/10-ports.conf
    systemctl daemon-reload
    systemctl restart ssh.socket
    apt-get update
    apt-get install -y wget unzip curl python3 python3-pip docker.io
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    az aks install-cli # kubectl and kubelogin
    wget -q https://releases.hashicorp.com/terraform/1.13.2/terraform_1.13.2_linux_amd64.zip
    unzip -o terraform_1.13.2_linux_amd64.zip -d /usr/local/bin/
    usermod -aG docker ${var.admin_username}
    systemctl enable --now docker
    pip3 install --break-system-packages kubernetes==32.0.1 azure-identity azure-storage-blob
    touch /var/lib/bootstrap-done
  EOF

  private_init = <<-EOF
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y wget redis-tools
    touch /var/lib/bootstrap-done
  EOF
}

resource "azurerm_public_ip" "public_vm" {
  name                = "pip-public-vm-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "public_vm" {
  name                = "nic-public-vm-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_public_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_vm.id
  }
}

resource "azurerm_network_interface" "private_vm" {
  name                = "nic-private-vm-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_private_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "public_vm" {
  network_interface_id      = azurerm_network_interface.public_vm.id
  network_security_group_id = var.nsg_public_vm_id
}

resource "azurerm_network_interface_security_group_association" "private_vm" {
  network_interface_id      = azurerm_network_interface.private_vm.id
  network_security_group_id = var.nsg_private_vm_id
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = {
    public  = { nic = azurerm_network_interface.public_vm.id, init = local.public_init }
    private = { nic = azurerm_network_interface.private_vm.id, init = local.private_init }
  }

  name                            = "${each.key}-vm-${var.env}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [each.value.nic]
  custom_data                     = base64encode(each.value.init)
  secure_boot_enabled             = true
  vtpm_enabled                    = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = local.ubuntu.publisher
    offer     = local.ubuntu.offer
    sku       = local.ubuntu.sku
    version   = local.ubuntu.version
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.vm_identity_id]
  }

  boot_diagnostics {} # managed storage; serial console and boot log

  tags = merge(var.tags, { Os = "ubuntu-2404" })

  depends_on = [
    azurerm_network_interface_security_group_association.public_vm,
    azurerm_network_interface_security_group_association.private_vm,
  ]
}
