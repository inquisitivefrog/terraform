# modules/compute/cloud_run.tf
# GCP counterpart of aws/single_instance/modules/compute/ecs_fargate.tf
# nginx with internal-only ingress and egress through the private subnet
# (AWS: Fargate task in the private subnet, no public IP). Scales to zero.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service

resource "google_cloud_run_v2_service" "nginx" {
  name                = "nginx-${var.env}"
  project             = var.project_id
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  deletion_protection = false

  template {
    service_account = var.cloudrun_sa_email

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = var.network_id
        subnetwork = var.subnet_private_id
      }
    }

    containers {
      image = "nginx:latest"
      ports {
        container_port = 80
      }
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  labels = {
    environment = var.env
  }
}
