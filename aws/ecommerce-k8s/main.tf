# main.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.94.1"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.3.7"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1.0"
    }
  }

  backend "s3" {
    # Configuration loaded from backend.hcl
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"

  region              = var.region
  vpc_name            = "ecommerce-vpc"
  vpc_cidr            = "10.0.0.0/16"
  azs                 = ["${var.region}a", "${var.region}b"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway  = true
  single_nat_gateway  = true
  cluster_name        = "ecommerce-cluster"
}

module "eks" {
  source = "./modules/eks"

  cluster_name                         = "ecommerce-cluster"
  cluster_version                      = "1.29"
  vpc_id                               = module.vpc.vpc_id
  subnet_ids                           = module.vpc.private_subnets
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["23.93.84.244/32"] 
  cluster_enabled_log_types            = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  node_groups = {
    default   = {
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
      labels         = {}
    }
  }
}

module "networking" {
  source = "./modules/networking"

  region                               = var.region
  vpc_id                               = module.vpc.vpc_id
  cluster_name                         = module.eks.cluster_name
  cluster_security_group_id            = module.eks.cluster_security_group_id
  cluster_endpoint_public_access_cidrs = ["23.93.84.244/32"] 
  private_route_table_ids              = module.vpc.private_route_table_ids
}

module "iam" {
  source = "./modules/iam"

  cluster_name              = module.eks.cluster_name
  oidc_provider_arn         = module.eks.oidc_provider_arn
  cluster_security_group_id = module.eks.cluster_security_group_id
  node_group_role_name      = module.eks.node_group_role_name
}

module "s3" {
  source = "./modules/s3"

  bucket_name  = "blued-ecommerce-app-us-east-1-prod"
  cluster_name = module.eks.cluster_name
}
