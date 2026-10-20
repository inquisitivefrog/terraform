# modules/vpc/vpc.tf
# GCP counterpart of aws/single_instance/modules/vpc
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network

# Custom-mode VPC. GCP gives every VPC an implied deny-all ingress, so there is
# no default security group to lock down; the internet gateway is the
# network's built-in default route.
resource "google_compute_network" "main" {
  name                    = "vpc-main-${var.env}"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Subnets are regional in GCP, so one private subnet spans every zone that
# AWS needed a subnet per AZ for. Same /24 offsets as AWS: public .3, private .4.
resource "google_compute_subnetwork" "public" {
  name                     = "public-${var.env}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = cidrsubnet(var.vpc_cidr_block, 8, 3)
  private_ip_google_access = true

  log_config { # VPC flow logs, sent to Cloud Logging
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "private" {
  name                     = "private-${var.env}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = cidrsubnet(var.vpc_cidr_block, 8, 4)
  private_ip_google_access = true

  # GKE VPC-native ranges
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr_block
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr_block
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud NAT gives the private subnet outbound access (AWS: NAT gateway + EIP)
resource "google_compute_router" "router" {
  name    = "router-${var.env}"
  project = var.project_id
  region  = var.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-${var.env}"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
