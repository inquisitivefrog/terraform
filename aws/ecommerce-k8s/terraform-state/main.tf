terraform {
  required_version = ">= 1.11.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.65"
    }
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "blue-elephant"

  allowed_account_ids = ["650836812595"] # Free-plan account; never grid-meter's
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "blue-elephant-ecommerce-terraform-state"
  force_destroy = true
  tags = {
    Name = "Terraform State"
  }
  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# State files hold secrets (e.g. the Argo CD server key), so encrypt them
# with a key whose use CloudTrail records. Destroying this root schedules the
# key for deletion (7 days), after which old state versions can't be read.
resource "aws_kms_key" "terraform_state" {
  description             = "ecommerce-k8s Terraform state"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/ecommerce-k8s-tfstate"
  target_key_id = aws_kms_key.terraform_state.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
