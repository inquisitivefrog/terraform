# modules/storage/outputs.tf

output "state_bucket_name" {
  value       = google_storage_bucket.state_bucket.name
  description = "Name of the GCS state bucket"
}

output "state_log_bucket_name" {
  value       = google_storage_bucket.state_log_bucket.name
  description = "Name of the GCS state log bucket"
}
