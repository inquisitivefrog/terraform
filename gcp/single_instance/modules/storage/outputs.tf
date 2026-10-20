# modules/storage/outputs.tf

output "dev_bucket_name" {
  value = google_storage_bucket.dev_bucket.name
}

output "log_bucket_name" {
  value = google_storage_bucket.log_bucket.name
}
