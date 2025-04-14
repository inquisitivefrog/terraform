# File 8: modules/kms/kms.tf

resource "aws_kms_key" "vpc_flow_logs_key" {
  description             = "KMS key for VPC Flow Logs encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy = jsonencode({
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
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        #Condition = {
        #  ArnLike = {
        #    "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/vpc/flow-logs/*"
        #  }
        #}
      }
    ]
  })
  tags = {
    Name = "vpc-flow-logs-kms-key"
  }
}
