# File 8: modules/kms/kms.tf

resource "aws_kms_key" "state_bucket_key" {
  description         = "KMS key for S3 state bucket (${var.env})"
  enable_key_rotation = true
  tags = {
    Name = "${var.env}-state-bucket-key"
  }
}

# Fixed name so backend.hcl files can reference the key without its random ID
resource "aws_kms_alias" "state_bucket_key" {
  name          = "alias/tfstate-${var.env}"
  target_key_id = aws_kms_key.state_bucket_key.key_id
}
