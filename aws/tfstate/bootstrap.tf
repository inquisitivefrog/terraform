terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

module "storage" {
  source         = "./modules/storage"
  account_id     = "084375569056" 
  employer       = "Fireworks Inc"
  env            = "prod"
  random_suffix  = ""
  region         = "us-west-1"
  tfstate_bucket = "bluedragon-tfstate-admin"
  state_bucket_key_arn         = "arn:aws:kms:us-west-1:084375569056:key/dummy"
  state_log_bucket_key_arn     = "arn:aws:kms:us-west-1:084375569056:key/dummy"
}
