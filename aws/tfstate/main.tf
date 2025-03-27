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
  vpc_id     = module.vpc.vpc_id
}

# Storage Module
module "storage" {
  source                       = "./modules/storage"
  account_id                   = data.aws_caller_identity.current.account_id
  random_suffix                = random_string.suffix.result
  sns_custom_key_arn           = module.kms.sns_custom_key_arn
}
