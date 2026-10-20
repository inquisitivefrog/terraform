# gcp/tfstate/environments/dev/main.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }
  backend "gcs" {} # see backend.hcl
}

provider "google" {
  project = var.project_id
  region  = var.region

  # Charge API quota to this project, not the ADC quota project (dairyfarm)
  billing_project       = var.project_id
  user_project_override = true
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

module "kms" {
  source        = "../../modules/kms"
  env           = var.env
  project_id    = var.project_id
  random_suffix = random_string.suffix.result
  region        = var.region
}

module "messages" {
  source                = "../../modules/messages"
  environment           = var.env
  gcs_service_agent     = module.kms.gcs_service_agent
  project_id            = var.project_id
  pubsub_logging_key_id = module.kms.pubsub_logging_key_id
  region                = var.region
}

module "storage" {
  source                  = "../../modules/storage"
  employer                = var.employer
  env                     = var.env
  project_id              = var.project_id
  pubsub_topic_logging_id = module.messages.pubsub_topic_logging_id
  random_suffix           = random_string.suffix.result
  region                  = var.region
  state_bucket_key_id     = module.kms.state_bucket_key_id
  tfstate_bucket          = var.tfstate_bucket
  enable_notifications    = true
}
