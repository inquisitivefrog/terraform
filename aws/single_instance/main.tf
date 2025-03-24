# File 3: main.tf
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.6"
    }
  }
  backend "s3" {
    # variables cannot be used in this block
    bucket         = "bluedragon-employer-prod"
    key            = "single_instance_terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
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
  sns_topic_example_arn        = module.messages.sns_topic_example_arn
  sns_topic_example_policy_arn = module.messages.sns_topic_example_policy_arn
  sns_custom_key_arn           = module.kms.sns_custom_key_arn
}

# VPC Module
module "vpc" {
  source                = "./modules/vpc"
  account_id            = data.aws_caller_identity.current.account_id
  availability_zones    = var.availability_zones
  kms_key_resource      = module.kms.vpc_flow_logs_key_resource
  region                = var.region
  vpc_cidr_block        = var.vpc_cidr_block
  vpc_flow_logs_key_arn = module.kms.vpc_flow_logs_key_arn
  vpc_flow_logs_key_id  = module.kms.vpc_flow_logs_key_id
}

# Networking Module
module "networking" {
  source                        = "./modules/networking"
  igw_id                        = module.vpc.igw_id
  my_laptop_cidr_block          = var.my_laptop_cidr_block
  nat_id                        = module.vpc.nat_id
  vpc_id                        = module.vpc.vpc_id
  vpc_subnet_private_cidr_block = module.vpc.vpc_subnet_private_cidr_block
  vpc_subnet_private_id         = module.vpc.vpc_subnet_private_id
  vpc_subnet_public_cidr_block  = module.vpc.vpc_subnet_public_cidr_block
  vpc_subnet_public_id          = module.vpc.vpc_subnet_public_id
}

# Compute Module
module "compute" {
  source                      = "./modules/compute"
  ec2_instance_profile_name   = module.identity.ec2_instance_profile_name
  ec2_keypair                 = var.ec2_keypair
  ecs_task_execution_role_arn = module.identity.ecs_task_execution_role_arn
  instance_type               = var.instance_type
  sg_private_ec2_id           = module.networking.sg_private_ec2_id
  sg_public_ec2_id            = module.networking.sg_public_ec2_id
  vpc_subnet_private_id       = module.vpc.vpc_subnet_private_id
  vpc_subnet_public_id        = module.vpc.vpc_subnet_public_id
}

# Cache Module
module "cache" {
  source                = "./modules/cache"
  redis_port            = var.redis_port
  sg_elasticache_id     = module.networking.sg_elasticache_id
  vpc_subnet_private_id = module.vpc.vpc_subnet_private_id
  vpc_subnet_public_id  = module.vpc.vpc_subnet_public_id
}

# Identity Module
module "identity" {
  source          = "./modules/identity"
  ec2_arns        = module.compute.ec2_arns
  ecs_cluster_arn = module.compute.ecs_cluster_arn
  ecs_service_arn = module.compute.ecs_service_arn
  elasticache_arn = module.cache.elasticache_arn
  s3_bucket_arn   = module.storage.s3_bucket_arn
  sns_topic_arns  = module.messages.sns_topic_arns
  private_ec2_arn = module.compute.private_ec2_arn
  public_ec2_arn  = module.compute.public_ec2_arn
}

# Messages Module
module "messages" {
  source             = "./modules/messages"
  account_id         = data.aws_caller_identity.current.account_id
  environment        = var.env
  log_bucket_arn     = module.storage.log_bucket_arn
  s3_bucket_arn      = module.storage.s3_bucket_arn
  sns_custom_key_arn = module.kms.sns_custom_key_arn
}
