# modules/kms/outputs.tf
# Key IDs are read through the IAM members so callers wait for the grants.

output "pubsub_logging_key_id" {
  value       = google_kms_crypto_key_iam_member.pubsub_logging_key.crypto_key_id
  description = "ID of the KMS key for the Pub/Sub logging topic"
}

output "state_bucket_key_id" {
  value       = google_kms_crypto_key_iam_member.gcs_state_bucket_key.crypto_key_id
  description = "ID of the KMS key for the GCS state bucket, for kms_encryption_key in backend.hcl"
}

output "gcs_service_agent" {
  value       = data.google_storage_project_service_account.gcs.email_address
  description = "Cloud Storage service agent email"
}
