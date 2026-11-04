output "endpoint_in_cluster" {
  description = "S3 endpoint for pods in the kind cluster"
  value       = "https://host.docker.internal:${var.port}"
}

output "endpoint_on_laptop" {
  description = "S3 endpoint from the laptop (aws --endpoint-url, with --ca-bundle ca_file)"
  value       = "https://localhost:${var.port}"
}

output "buckets" {
  description = "Bucket per engine"
  value       = local.buckets
}

output "keys_file" {
  description = "The S3 identities (one key per engine); not in state"
  value       = "${var.keys_dir}/s3.json"
}

output "ca_file" {
  description = "The CA certificate clients trust for the endpoint (public)"
  value       = "${var.keys_dir}/ca.crt"
}

output "ca_pem" {
  description = "That CA certificate's contents, for the clusters' CA Secrets (public: no key)"
  value       = file("${var.keys_dir}/ca.crt")
}
