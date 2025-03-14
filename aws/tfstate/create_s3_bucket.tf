# File 1: create_bucket.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl
# https://registry.terraform.io/providers/PixarV/r4/latest/docs/resources/s3_bucket_versioning
# https://registry.terraform.io/providers/hashicorp/aws/5.83.1/docs/resources/s3_bucket_replication_configuration
# https://registry.terraform.io/providers/aaronfeng/aws/latest/docs/resources/s3_bucket_public_access_block
# https://github.com/hashicorp/terraform-provider-aws/blob/main/website/docs/r/s3_bucket_server_side_encryption_configuration.html.markdown
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table   

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.5"
    }
  }
}

provider "aws" {
  region = "us-west-1" # or your region
}

resource "aws_s3_bucket" "state_bucket" {
  bucket        = var.tfstate_bucket
  force_destroy = false
  tags = {
    Name        = var.employer
    Environment = var.env
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket                  = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add this new resource before the ACL resource
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket             = aws_s3_bucket.state_bucket.id

  rule {
    object_ownership = "ObjectWriter" # or "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "state_bucket_acl" {
  bucket     = aws_s3_bucket.state_bucket.id
  acl        = "private"
  depends_on = [
    aws_s3_bucket_public_access_block.block_public_access,
    aws_s3_bucket_ownership_controls.ownership
  ]
}

resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket   = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state_bucket_lifecycle" {
  bucket   = aws_s3_bucket.state_bucket.id

  rule {
    id                = "move_to_glacier"
    status            = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket_encryption" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_kms_key" "dynamodb_key" {
  description             = "KMS key for DynamoDB terraform-locks"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  server_side_encryption {
    enabled = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }
  point_in_time_recovery {
    enabled = true
  }
  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "state_log_bucket" {
  bucket = "${var.tfstate_bucket}-logs"
  force_destroy = false
  tags = {
    Name        = "${var.employer}-logs"
    Environment = var.env
  }
}

resource "aws_s3_bucket_public_access_block" "state_log_bucket" {
  bucket                  = aws_s3_bucket.state_log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_log_bucket" {
  bucket = aws_s3_bucket.state_log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Add logging to state bucket
resource "aws_s3_bucket_logging" "state_bucket_logging" {
  bucket        = aws_s3_bucket.state_bucket.id
  target_bucket = aws_s3_bucket.state_log_bucket.id
  target_prefix = "state-logs/"
}
