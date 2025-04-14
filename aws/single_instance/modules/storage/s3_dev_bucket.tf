# File 22: modules/storage/s3.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

resource "aws_s3_bucket" "dev_bucket" {
  bucket = "bluedragon-dev-bucket-${var.random_suffix}"

  # Ensure the log bucket itself is secure
  # checkov:skip=CKV_AWS_144:Single-region setup, CRR not required
  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "bluedragon-dev-bucket"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dev_bucket_encryption" {
  bucket = aws_s3_bucket.dev_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.sns_custom_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "dev_bucket_versioning" {
  bucket = aws_s3_bucket.dev_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "dev_bucket_logging" {
  bucket        = aws_s3_bucket.dev_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_notification" "dev_bucket_notification" {
  bucket = aws_s3_bucket.dev_bucket.id

  topic {
    topic_arn     = var.sns_topic_example_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "logs/"
  }
}

resource "aws_s3_bucket_public_access_block" "dev_bucket_access_block" {
  bucket = aws_s3_bucket.dev_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "dev_bucket_lifecycle" {
  bucket = aws_s3_bucket.dev_bucket.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = 90
    }

    filter {
      prefix = "logs/"
    }
  }

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    filter {
      prefix = ""
    }
  }
  depends_on = [aws_s3_bucket.dev_bucket] 
}
