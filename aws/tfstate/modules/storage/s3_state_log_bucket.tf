# File 1: create_bucket.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl
# https://registry.terraform.io/providers/PixarV/r4/latest/docs/resources/s3_bucket_versioning
# https://registry.terraform.io/providers/hashicorp/aws/5.83.1/docs/resources/s3_bucket_replication_configuration
# https://registry.terraform.io/providers/aaronfeng/aws/latest/docs/resources/s3_bucket_public_access_block
# https://github.com/hashicorp/terraform-provider-aws/blob/main/website/docs/r/s3_bucket_server_side_encryption_configuration.html.markdown
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table

resource "aws_s3_bucket" "state_log_bucket" {
  bucket        = "${var.tfstate_bucket}-logs-${var.random_suffix}"
  force_destroy = false
  tags = {
    Name        = "${var.employer}-logs"
    Environment = var.env
  }
}

resource "aws_s3_bucket_policy" "state_log_bucket_policy" {
  bucket = aws_s3_bucket.state_log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = ["s3:PutObject"]
        Resource  = "${aws_s3_bucket.state_log_bucket.arn}/state-logs/*"
        Condition = {
          ArnLike      = { "aws:SourceArn" = "arn:aws:s3:::${var.tfstate_bucket}-${var.random_suffix}" }
          StringEquals = { "aws:SourceAccount" = var.account_id }
        }
      }
    ]
  })
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
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.state_log_bucket_key_arn
    }
  }
}

resource "aws_s3_bucket_notification" "state_log_bucket_notification" {
  bucket = aws_s3_bucket.state_log_bucket.id

  topic {
    topic_arn     = var.sns_topic_logging_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "logs/"
  }

  depends_on = [aws_s3_bucket_policy.state_log_bucket_policy]
}

resource "aws_s3_bucket_versioning" "state_log_bucket_versioning" {
  bucket = aws_s3_bucket.state_log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
