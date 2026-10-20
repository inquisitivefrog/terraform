# gcp/tfstate/bootstrap/dev/main.tf
# create GCS bucket to store terraform.tfstate files (state for this root is local)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.7"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "us-west1"

  # Charge API quota to this project, not the ADC quota project (dairyfarm)
  billing_project       = var.project_id
  user_project_override = true
}

# APIs the tfstate layer needs; left enabled on destroy (shared by dev and prod)
resource "google_project_service" "apis" {
  for_each           = toset(["cloudkms.googleapis.com", "pubsub.googleapis.com", "storage.googleapis.com"])
  service            = each.key
  disable_on_destroy = false
}

module "storage" {
  source         = "../../modules/storage"
  employer       = "Fireworks Inc"
  env            = "dev"
  project_id     = var.project_id
  random_suffix  = ""
  region         = "us-west1"
  tfstate_bucket = "bluedragon-tfstate-admin-dev"

  depends_on = [google_project_service.apis]
}
