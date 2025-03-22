# File 22: modules/storage/s3.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.log_bucket.arn}/logs/*"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.dev_bucket.arn
          }
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "bluedragon-log-bucket-${var.random_suffix}"

  # Ensure the log bucket itself is secure
  lifecycle {
    prevent_destroy = true  # Protect log data
  }

  tags = {
    Name = "bluedragon-log-bucket"
  }
}

resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_public_access_block" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      kms_master_key_id = var.sns_custom_key_arn 
    }
  }
}

resource "aws_s3_bucket_notification" "log_bucket_notification" {
  bucket = aws_s3_bucket.log_bucket.id

  topic {
    topic_arn     = var.sns_topic_example_arn 
    events        = ["s3:ObjectCreated:*"] 
    filter_prefix = "logs/" 
  }

  depends_on = [
    aws_s3_bucket_policy.log_bucket_policy,
    var.sns_topic_example_policy_arn
  ]
}

resource "aws_s3_bucket" "dev_bucket" {
  bucket = "bluedragon-dev-bucket-${var.random_suffix}"

  tags = {
    Name = "bluedragon-dev-bucket"
  }
}

resource "aws_s3_bucket_logging" "dev_bucket_logging" {
  bucket = aws_s3_bucket.dev_bucket.id
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
      prefix = "" # Applies to all objects
    }
  }
}
