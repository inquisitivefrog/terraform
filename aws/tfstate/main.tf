# File 1: main.tf

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
}

provider "aws" {
  region = "us-west-1"
}

data "aws_caller_identity" "current" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false # AWS S3 Buckets must use lowercase
}

# Key Message Service Module
module "kms" {
  source     = "./modules/kms"
  account_id = data.aws_caller_identity.current.account_id
  region     = var.region
}

# Messages Module
module "messages" {
  source              = "./modules/messages"
  account_id          = data.aws_caller_identity.current.account_id
  environment         = var.env
  random_suffix       = random_string.suffix.result
  sns_logging_key_arn = module.kms.sns_logging_key_arn
  tfstate_bucket      = var.tfstate_bucket
}

# Storage Module
module "storage" {
  source                       = "./modules/storage"
  account_id                   = data.aws_caller_identity.current.account_id
  dynamodb_key_arn             = module.kms.dynamodb_key_arn
  employer                     = var.employer
  env                          = var.env
  random_suffix                = random_string.suffix.result
  region                       = var.region
  sns_topic_logging_arn        = module.messages.sns_topic_logging_arn
  sns_topic_logging_policy_arn = module.messages.sns_topic_logging_policy_arn
  state_bucket_key_arn         = module.kms.state_bucket_key_arn
  state_log_bucket_key_arn     = module.kms.state_log_bucket_key_arn
  tfstate_bucket               = var.tfstate_bucket
}
