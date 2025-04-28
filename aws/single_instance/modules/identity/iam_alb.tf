# File ../../modules/identity/iam_alb.tf

resource "aws_iam_role" "alb_controller" {
  count = var.enable_ingress ? 1 : 0
  name  = "ALBControllerRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "alb_controller" {
  count = var.enable_ingress ? 1 : 0
  name  = "ALBControllerPolicy"
  role  = aws_iam_role.alb_controller[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:Describe*",
          "acm:DescribeCertificate",
          "acm:ListCertificates"
        ]
        Resource = "*"
      }
    ]
  })
}
