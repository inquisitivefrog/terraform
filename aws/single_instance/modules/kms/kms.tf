# File 8: modules/kms/kms.tf

resource "aws_kms_key" "sns_custom_key" {
  description             = "Custom key for SNS encryption"
  deletion_window_in_days = 7
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation     = true
  tags = {
    Name = "sns-custom-key"
  }
}

resource "aws_kms_alias" "sns_custom_key_alias" {
  name          = "alias/my-custom-sns-key"
  target_key_id = aws_kms_key.sns_custom_key.key_id
}

resource "aws_kms_key" "symmetric_key" {
  description             = "An example symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 20
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:user/bluedragon"
        }
        Action = [
          "kms:ReplicateKey",
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ]
        Resource = "*"
      }
    ]
  })
  tags = {
    Name = "symmetric-key"
  }
}

resource "aws_kms_key" "asymmetric_key" {
  description              = "RSA-3072 asymmetric KMS key for signing and verification"
  customer_master_key_spec = "RSA_3072"
  key_usage                = "SIGN_VERIFY"
  enable_key_rotation      = false
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:role/Admin"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:role/Developer"
        }
        Action = [
          "kms:Sign",
          "kms:Verify",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
  tags = {
    Name = "asymmetric-key"
  }
}

# File: modules/kms/kms.tf
resource "aws_kms_key" "vpc_flow_logs_key" {
  description             = "KMS key for VPC Flow Logs encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow CloudWatch Logs to use the key"
        Effect    = "Allow"
        Principal = { Service = "logs.${var.region}.amazonaws.com" }
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:EncryptionContext:LogGroupArn" = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/vpc/flow-logs/${var.vpc_id}"
          }
        }
      }
    ]
  })
  tags = {
    Name = "vpc-flow-logs-kms-key"
  }
}
