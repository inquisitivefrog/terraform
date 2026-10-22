# File 1: tfstate/environments/prod/main.tf
# The KMS key that encrypts single_instance state (alias/tfstate-prod, named
# in single_instance/environments/prod/backend.hcl). Until 2026-10-21 this
# stage also made a suffixed state bucket, a log bucket and an SNS topic
# with its own KMS key; nothing stored state there, so they were removed.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.65"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

module "kms" {
  source = "../../modules/kms"
  env    = var.env
}
