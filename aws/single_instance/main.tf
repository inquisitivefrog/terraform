# File 3: main.tf
terraform {
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
    encrypt        = true # if you're using server-side encryption
  }
}

provider "aws" {
  region = var.region
}

# VPC Module
module "vpc" {
  source             = "./modules/vpc"
  availability_zones = var.availability_zones
  vpc_cidr_block     = var.vpc_cidr_block
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
  source                = "./modules/identity"
}

data "aws_caller_identity" "current" {}

# Messages Module
module "messages" {
  source      = "./modules/messages"
  environment = var.env
  account_id  = data.aws_caller_identity.current.account_id
}
