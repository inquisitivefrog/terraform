# File 8: modules/kms/kms_eks.tf

resource "aws_kms_key" "eks_key" {
  description             = "KMS key for EKS cluster encryption"
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
        Sid       = "Allow EKS to use the key"
        Effect    = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
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
    Name = "eks-kms-key"
  }
}

resource "aws_kms_alias" "eks_key_alias" {
  name          = "alias/eks-key"
  target_key_id = aws_kms_key.eks_key.key_id
}
