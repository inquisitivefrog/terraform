# tfstate/bootstrap.tf
# create AWS S3 buckets to store terraform.tfstate files

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.65"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

module "storage" {
  source         = "../../modules/storage"
  account_id     = data.aws_caller_identity.current.account_id
  employer       = "Fireworks Inc"
  env            = "dev"
  random_suffix  = ""
  region         = "us-west-2"
  tfstate_bucket = "bluedragon-tfstate-admin-dev"
}
