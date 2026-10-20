# modules/kms/outputs.tf
# Key IDs are read through the IAM grants so callers wait for them.

output "asymmetric_key_id" {
  value = google_kms_crypto_key.asymmetric_key.id
}

output "gke_key_id" {
  value       = google_kms_crypto_key_iam_member.gke_key.crypto_key_id
  description = "KMS key for GKE secrets encryption"
}

output "key_ring_id" {
  value = google_kms_key_ring.main.id
}

output "messages_key_id" {
  value       = google_kms_crypto_key_iam_binding.messages_key.crypto_key_id
  description = "KMS key for Pub/Sub topics and buckets"
}

output "symmetric_key_id" {
  value = google_kms_crypto_key.symmetric_key.id
}

output "gcs_service_agent" {
  value = data.google_storage_project_service_account.gcs.email_address
}
