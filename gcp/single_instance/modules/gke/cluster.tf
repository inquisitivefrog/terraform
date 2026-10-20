# modules/gke/cluster.tf
# GCP counterpart of aws/single_instance/modules/eks
# Zonal Standard cluster: private nodes, public endpoint limited to the
# authorized CIDRs (AWS: public_access_cidrs), secrets encrypted with CMEK.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster

resource "google_container_cluster" "this" {
  name                = "gke-${var.env}-${var.random_suffix}"
  project             = var.project_id
  location            = var.zone # zonal: the free-tier cluster fee credit covers one zonal cluster
  network             = var.network_id
  subnetwork          = var.subnet_private_id
  deletion_protection = false

  # Manage nodes in the separate pool below (AWS: managed node group)
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR" # GKE picks the version; AWS pinned eks_version
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false
    dynamic "cidr_blocks" {
      for_each = var.authorized_cidrs
      content {
        cidr_block   = cidr_blocks.value.cidr
        display_name = cidr_blocks.value.name
      }
    }
  }

  database_encryption {
    state    = "ENCRYPTED"
    key_name = var.kms_key_id
  }

  # Pods get Google identities without node keys (AWS equivalent: IRSA)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  datapath_provider = "ADVANCED_DATAPATH" # Dataplane V2, enforces NetworkPolicy

  resource_labels = {
    environment = var.env
  }
}

resource "google_container_node_pool" "this" {
  name     = "np-${var.env}-${var.random_suffix}"
  project  = var.project_id
  location = var.zone
  cluster  = google_container_cluster.this.name

  node_count = var.node_count
  autoscaling {
    min_node_count = 1
    max_node_count = var.node_max_count
  }

  lifecycle {
    ignore_changes = [node_count] # the autoscaler owns it after creation
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.machine_type
    image_type      = "COS_CONTAINERD"
    disk_size_gb    = 20
    disk_type       = "pd-balanced"
    service_account = var.node_sa_email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    tags            = [var.node_tag]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      environment = var.env
    }
  }
}
