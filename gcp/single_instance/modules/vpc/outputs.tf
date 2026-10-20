# modules/vpc/outputs.tf

output "network_id" {
  value = google_compute_network.main.id
}

output "network_name" {
  value = google_compute_network.main.name
}

output "subnet_private_cidr_block" {
  value = google_compute_subnetwork.private.ip_cidr_range
}

output "subnet_private_id" {
  value = google_compute_subnetwork.private.id
}

output "subnet_public_cidr_block" {
  value = google_compute_subnetwork.public.ip_cidr_range
}

output "subnet_public_id" {
  value = google_compute_subnetwork.public.id
}
