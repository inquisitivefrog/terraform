# File 7: modules/messages/sns.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription

resource "aws_sns_topic" "example" {
  name = "example-topic"
  tags = {
    Name        = "example-topic-${var.env}"
    Environment = var.env
    AccountID   = var.account_id
  }

  # At Rest Encryption with AWS Key Management Service (KMS) custom key
  kms_master_key_id = var.sns_custom_key_arn

  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

resource "aws_sns_topic_policy" "example_policy" {
  arn = aws_sns_topic.example.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.example.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = [
              var.s3_bucket_arn,
              var.log_bucket_arn
            ]
          }
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic" "custom" {
  # First In, First Out Policy
  name = "custom-topic.fifo"
  tags = {
    Name        = "custom-topic-${var.env}"
    Environment = var.env
    AccountID   = var.account_id
  }
  fifo_topic                  = true
  content_based_deduplication = true
  # At Rest Encryption with AWS Key Management Service (KMS) custom key
  kms_master_key_id = var.sns_custom_key_arn
}

# In Transit Encryption with HTTPS
resource "aws_sns_topic_subscription" "example" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "https"
  endpoint  = "https://example.com/sns-notification"
}
