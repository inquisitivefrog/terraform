# gcp/single_instance/environments outputs

output "cloud_run_uri" {
  description = "Internal-only nginx service URL"
  value       = module.compute.cloud_run_uri
}

output "gke_cluster_endpoint" {
  value = module.gke.cluster_endpoint
}

output "gke_cluster_name" {
  value = module.gke.cluster_name
}

output "kubeconfig_command" {
  description = "Run this to point kubectl at the GKE cluster"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --zone ${module.gke.cluster_location} --project ${var.project_id}"
}

output "private_vm_ip" {
  value = module.compute.private_vm_ip
}

output "public_vm_ip" {
  value = module.compute.public_vm_ip
}

output "redis_host" {
  value = module.cache.redis_host
}

output "redis_port" {
  value = module.cache.redis_port
}

output "redis_auth_string" {
  value     = module.cache.redis_auth_string
  sensitive = true
}

output "example_topic_id" {
  value = module.messages.example_topic_id
}

output "project_id" {
  value = var.project_id
}

output "zone" {
  description = "Zone of the VMs, GKE and Memorystore"
  value       = local.zone
}
