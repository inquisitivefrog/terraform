# modules/gke/outputs.tf

output "cluster_ca_certificate" {
  value = google_container_cluster.this.master_auth[0].cluster_ca_certificate
}

output "cluster_endpoint" {
  value = google_container_cluster.this.endpoint
}

output "cluster_name" {
  value = google_container_cluster.this.name
}

output "cluster_location" {
  value = google_container_cluster.this.location
}

output "node_pool_id" {
  value = google_container_node_pool.this.id
}
