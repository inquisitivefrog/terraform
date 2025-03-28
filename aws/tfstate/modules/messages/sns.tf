# File 7: modules/messages/sns.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription

resource "aws_sns_topic" "logging" {
  name              = "logging-topic"
  kms_master_key_id = var.sns_logging_key_arn
  delivery_policy   = <<EOF
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
  tags = {
    Name        = "logging-topic-${var.environment}"
    Environment = var.environment
    AccountID   = var.account_id
  }
}

resource "aws_sns_topic_policy" "allow_s3" {
  arn = aws_sns_topic.logging.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Publish"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.logging.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = [
              "arn:aws:s3:::${var.tfstate_bucket}-${var.random_suffix}",
              "arn:aws:s3:::${var.tfstate_bucket}-logs-${var.random_suffix}"
            ]
          }
        }
      }
    ]
  })
}
