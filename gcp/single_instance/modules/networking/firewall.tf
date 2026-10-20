# modules/networking/firewall.tf
# GCP counterpart of aws/single_instance/modules/networking/security_group.tf
# Security groups become firewall rules aimed at network tags. GCP firewalls
# allow all egress by default, so each tag gets explicit allows plus a
# low-priority deny to match the AWS security groups' egress lists.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall

locals {
  public_tag  = "public-vm-${var.env}"
  private_tag = "private-vm-${var.env}"
}

# --- public VM (AWS: public-ec2) ---

resource "google_compute_firewall" "public_vm_from_laptop" {
  name          = "public-vm-from-laptop-${var.env}"
  project       = var.project_id
  network       = var.network_id
  direction     = "INGRESS"
  source_ranges = [var.my_laptop_cidr_block]
  target_tags   = [local.public_tag]
  description   = "SSH, ICMP, HTTP and HTTPS from my laptop"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }
  allow {
    protocol = "icmp"
  }
}

# Identity-Aware Proxy TCP forwarding: SSH over HTTPS for laptops whose
# network blocks port 22 (gcloud compute ssh --tunnel-through-iap)
resource "google_compute_firewall" "public_vm_from_iap" {
  name          = "public-vm-from-iap-${var.env}"
  project       = var.project_id
  network       = var.network_id
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = [local.public_tag]
  description   = "SSH from IAP TCP forwarding"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "public_vm_egress" {
  name               = "public-vm-egress-${var.env}"
  project            = var.project_id
  network            = var.network_id
  direction          = "EGRESS"
  priority           = 1000
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = [local.public_tag]
  description        = "HTTP and HTTPS out (Google APIs, GKE, Ubuntu repos)"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "public_vm_egress_internal" {
  name               = "public-vm-egress-internal-${var.env}"
  project            = var.project_id
  network            = var.network_id
  direction          = "EGRESS"
  priority           = 1000
  destination_ranges = [var.my_laptop_cidr_block, var.subnet_public_cidr_block, var.subnet_private_cidr_block]
  target_tags        = [local.public_tag]
  description        = "All traffic to laptop and VPC subnets"

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "public_vm_egress_deny" {
  name               = "public-vm-egress-deny-${var.env}"
  project            = var.project_id
  network            = var.network_id
  direction          = "EGRESS"
  priority           = 65000
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = [local.public_tag]

  deny {
    protocol = "all"
  }
}

# --- private VM (AWS: private-ec2) ---

resource "google_compute_firewall" "private_vm_from_public" {
  name          = "private-vm-from-public-${var.env}"
  project       = var.project_id
  network       = var.network_id
  direction     = "INGRESS"
  source_ranges = [var.subnet_public_cidr_block]
  target_tags   = [local.private_tag]
  description   = "SSH and ICMP from the public subnet"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "private_vm_egress" {
  name               = "private-vm-egress-${var.env}"
  project            = var.project_id
  network            = var.network_id
  direction          = "EGRESS"
  priority           = 1000
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = [local.private_tag]
  description        = "HTTP and HTTPS out via Cloud NAT (Google APIs, apt)"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "private_vm_egress_ssh" {
  name               = "private-vm-egress-ssh-${var.env}"
  project            = var.project_id
  network            = var.network_id
  direction          = "EGRESS"
  priority           = 1000
  destination_ranges = [var.vpc_cidr_block]
  target_tags        = [local.private_tag]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "private_vm_egress_redis" {
  name               = "private-vm-egress-redis-${var.env}"
  project            = var.project_id
  network            = var.network_id
  direction          = "EGRESS"
  priority           = 1000
  destination_ranges = [var.redis_cidr_block]
  target_tags        = [local.private_tag]
  description        = "Redis to Memorystore"

  allow {
    protocol = "tcp"
    ports    = [tostring(var.redis_port)]
  }
}

resource "google_compute_firewall" "private_vm_egress_deny" {
  name               = "private-vm-egress-deny-${var.env}"
  project            = var.project_id
  network            = var.network_id
  direction          = "EGRESS"
  priority           = 65000
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = [local.private_tag]

  deny {
    protocol = "all"
  }
}

# --- GKE nodes (AWS: eks-cluster SG). GKE adds its own control-plane and
# intra-cluster rules; this allows the VPC to reach node services. ---

resource "google_compute_firewall" "gke_nodes_from_vpc" {
  name          = "gke-nodes-from-vpc-${var.env}"
  project       = var.project_id
  network       = var.network_id
  direction     = "INGRESS"
  source_ranges = [var.vpc_cidr_block]
  target_tags   = [var.gke_node_tag]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}
