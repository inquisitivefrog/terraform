terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.65"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.1"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region  = var.region
  profile = "default"
}
