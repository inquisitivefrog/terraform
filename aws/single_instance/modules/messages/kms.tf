# File 21: modules/messages/kms.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key
# https://registry.terraform.io/providers/-/aws/latest/docs/resources/kms_alias

resource "aws_kms_key" "custom_key" {
  description             = "Custom key for SNS encryption"
  deletion_window_in_days = 7
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation = true
}

resource "aws_kms_alias" "custom_key_alias" {
  name          = "alias/my-custom-sns-key"
  target_key_id = aws_kms_key.custom_key.key_id
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
        },
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          #AWS = "arn:aws:iam::${var.account_id}:root"
          AWS = "arn:aws:iam::${var.account_id}:user/bluedragon"
        },
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
          #AWS = "arn:aws:iam::${var.account_id}:user/bluedragon"
        },
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ],
        Resource = "*"
      }
    ]
  })
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
        },
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:role/Admin"
        },
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
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:role/Developer"
        },
        Action = [
          "kms:Sign",
          "kms:Verify",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
}
