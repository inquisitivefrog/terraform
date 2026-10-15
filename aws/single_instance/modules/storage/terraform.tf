terraform {
  required_version = ">= 1.11.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.65"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.3"
    }
  }
}
