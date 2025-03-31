# File 1: tfstate/environments/dev/main.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
  backend "s3" {} # see backend.hcl
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

module "kms" {
  source     = "../../modules/kms"
  account_id = data.aws_caller_identity.current.account_id
  region     = var.region
}

module "messages" {
  source              = "../../modules/messages"
  account_id          = data.aws_caller_identity.current.account_id
  environment         = var.env
  random_suffix       = random_string.suffix.result
  sns_logging_key_arn = module.kms.sns_logging_key_dev_arn
  tfstate_bucket      = var.tfstate_bucket
}

module "storage" {
  source                       = "../../modules/storage"
  account_id                   = data.aws_caller_identity.current.account_id
  employer                     = var.employer
  env                          = var.env
  random_suffix                = random_string.suffix.result
  region                       = var.region
  sns_topic_logging_arn        = module.messages.sns_topic_logging_arn
  sns_topic_logging_policy_arn = module.messages.sns_topic_logging_policy_arn
  state_bucket_key_arn         = module.kms.state_bucket_key_dev_arn
  state_log_bucket_key_arn     = module.kms.log_bucket_key_dev_arn
  tfstate_bucket               = var.tfstate_bucket
}
