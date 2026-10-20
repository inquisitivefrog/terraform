# modules/compute/vm.tf
# GCP counterpart of aws/single_instance/modules/compute/ec2.tf
# SSH uses OS Login (your Google identity), so no key pair is stored
# anywhere; reach the private VM through the public one with ssh -J.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

locals {
  # Startup scripts run on every boot; the marker makes the install run once.
  public_startup = <<-EOF
    #!/bin/bash
    set -e
    [ -f /var/lib/bootstrap-done ] && exit 0
    apt-get update
    apt-get install -y wget unzip apt-transport-https ca-certificates gnupg curl
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
    apt-get update
    apt-get install -y google-cloud-cli kubectl google-cloud-cli-gke-gcloud-auth-plugin
    wget -q https://releases.hashicorp.com/terraform/1.13.2/terraform_1.13.2_linux_amd64.zip
    unzip -o terraform_1.13.2_linux_amd64.zip -d /usr/local/bin/
    apt-get install -y python3 python3-pip docker.io
    usermod -aG docker ubuntu || true
    systemctl enable --now docker
    pip3 install --break-system-packages kubernetes==32.0.1 google-cloud-storage
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install
    touch /var/lib/bootstrap-done
  EOF

  private_startup = <<-EOF
    #!/bin/bash
    set -e
    [ -f /var/lib/bootstrap-done ] && exit 0
    apt-get update
    apt-get install -y wget redis-tools
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install
    touch /var/lib/bootstrap-done
  EOF

  vm_metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
  }
}

resource "google_compute_instance" "public" {
  name         = "public-vm-${var.env}"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type
  tags         = [var.public_vm_tag]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_public_id
    access_config {} # ephemeral public IP (AWS: associate_public_ip_address)
  }

  service_account {
    email  = var.vm_sa_email
    scopes = ["cloud-platform", "userinfo-email"] # email lets GKE RBAC match the account by name
  }

  allow_stopping_for_update = true # scope changes need a stop/start

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata                = local.vm_metadata
  metadata_startup_script = local.public_startup

  labels = {
    environment = var.env
    os          = "ubuntu-2404"
  }
}

resource "google_compute_instance" "private" {
  name         = "private-vm-${var.env}"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type
  tags         = [var.private_vm_tag]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_private_id # no access_config: no public IP
  }

  service_account {
    email  = var.vm_sa_email
    scopes = ["cloud-platform", "userinfo-email"] # email lets GKE RBAC match the account by name
  }

  allow_stopping_for_update = true # scope changes need a stop/start

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata                = local.vm_metadata
  metadata_startup_script = local.private_startup

  labels = {
    environment = var.env
    os          = "ubuntu-2404"
  }
}
