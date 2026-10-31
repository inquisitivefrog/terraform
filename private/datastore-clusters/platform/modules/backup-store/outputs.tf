output "endpoint_in_cluster" {
  description = "S3 endpoint for pods in the kind cluster"
  value       = "http://host.docker.internal:${var.port}"
}

output "endpoint_on_laptop" {
  description = "S3 endpoint from the laptop (aws --endpoint-url)"
  value       = "http://localhost:${var.port}"
}

output "buckets" {
  description = "Bucket per engine"
  value       = local.buckets
}

output "keys_file" {
  description = "The S3 identities (one key per engine); not in state"
  value       = "${var.keys_dir}/s3.json"
}
