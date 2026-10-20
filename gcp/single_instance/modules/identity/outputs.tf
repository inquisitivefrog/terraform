# modules/identity/outputs.tf

output "admin_sa_email" {
  value = google_service_account.admin.email
}

output "cloudrun_sa_email" {
  value = google_service_account.cloudrun.email
}

output "developer_sa_email" {
  value = google_service_account.developer.email
}

output "gke_node_sa_email" {
  value = google_service_account.gke_node.email
}

output "operator_sa_emails" {
  value = { for k, sa in google_service_account.operators : k => sa.email }
}

output "vm_sa_email" {
  value = google_service_account.vm.email
}
