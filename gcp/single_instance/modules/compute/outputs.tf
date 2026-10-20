# modules/compute/outputs.tf

output "cloud_run_service_name" {
  value = google_cloud_run_v2_service.nginx.name
}

output "cloud_run_uri" {
  value = google_cloud_run_v2_service.nginx.uri
}

output "private_vm_ip" {
  value = google_compute_instance.private.network_interface[0].network_ip
}

output "private_vm_name" {
  value = google_compute_instance.private.name
}

output "public_vm_ip" {
  value = google_compute_instance.public.network_interface[0].access_config[0].nat_ip
}

output "public_vm_name" {
  value = google_compute_instance.public.name
}

output "zone" {
  value = var.zone
}
