# tfstate/bootstrap.tf
# create AWS S3 buckets to store terraform.tfstate files

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "storage" {
  source                   = "../../modules/storage"
  account_id               = "084375569056"
  employer                 = "Fireworks Inc"
  env                      = "dev"
  random_suffix            = ""
  region                   = "us-west-2"
  tfstate_bucket           = "bluedragon-tfstate-admin-dev"
  state_bucket_key_arn     = "arn:aws:kms:us-west-2:084375569056:key/dummy"
  state_log_bucket_key_arn = "arn:aws:kms:us-west-2:084375569056:key/dummy"
}
