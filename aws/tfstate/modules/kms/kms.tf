# File 8: modules/kms/kms.tf

resource "aws_kms_key" "state_bucket_key" {
  description         = "KMS key for S3 state bucket"
  enable_key_rotation = true
}

resource "aws_kms_key" "log_bucket_key" {
  description         = "KMS key for S3 state log bucket"
  enable_key_rotation = true
}

resource "aws_kms_key" "dynamodb_key" {
  description             = "KMS key for DynamoDB terraform-locks"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key" "sns_logging_key" {
  description              = "Custom key for SNS encryption"
  deletion_window_in_days  = 7
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowRoot"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowS3"
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid       = "Allow S3 to use the key"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
  tags = {
    Name = "sns-custom-key"
  }
}
