output "state_bucket_key_id" {
  value       = module.kms.state_bucket_key_id
  description = "Put in later roots' backend.hcl as kms_encryption_key"
}

output "state_bucket_name" {
  value = module.storage.state_bucket_name
}

output "state_log_bucket_name" {
  value = module.storage.state_log_bucket_name
}
