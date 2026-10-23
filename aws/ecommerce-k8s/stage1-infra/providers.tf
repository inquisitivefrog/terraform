terraform {
  required_version = ">= 1.11.0" # S3 backend use_lockfile
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.65"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region  = var.region
  profile = "blue-elephant"

  allowed_account_ids = ["650836812595"] # Free-plan account; never grid-meter's
}
