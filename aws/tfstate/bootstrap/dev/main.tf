# tfstate/bootstrap.tf
# create AWS S3 buckets to store terraform.tfstate files

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.65"
    }
  }
}

provider "aws" {
  region              = "us-east-2"
  profile             = "blue-elephant"
  allowed_account_ids = ["650836812595"] # Free-plan account; never grid-meter's
}

data "aws_caller_identity" "current" {}

module "storage" {
  source         = "../../modules/storage"
  account_id     = data.aws_caller_identity.current.account_id
  employer       = "Fireworks Inc"
  env            = "dev"
  random_suffix  = ""
  tfstate_bucket = "blue-elephant-tfstate-admin-dev"
}
