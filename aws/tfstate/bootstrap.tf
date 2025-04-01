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
  account_id     = "084375569056"  # From your aws sts output
  employer       = "Fireworks Inc"
  env            = "prod"
  random_suffix  = "temp"          # Temporary suffix
  region         = "us-west-1"
  tfstate_bucket = "bluedragon-tfstate-admin"
  # Dummy values for dependencies (adjust if needed)
  sns_topic_logging_arn        = "arn:aws:sns:us-west-1:084375569056:dummy"
  sns_topic_logging_policy_arn = "arn:aws:iam::084375569056:policy/dummy"
  state_bucket_key_arn         = "arn:aws:kms:us-west-1:084375569056:key/dummy"
  state_log_bucket_key_arn     = "arn:aws:kms:us-west-1:084375569056:key/dummy"
}
