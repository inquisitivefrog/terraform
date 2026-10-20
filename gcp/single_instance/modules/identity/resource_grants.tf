# modules/identity/resource_grants.tf
# Resource-scoped grants, like the AWS policies' Resource lists.

# Developer: read the VMs and the dev bucket (AWS: DeveloperPolicy)
resource "google_compute_instance_iam_member" "developer_vms" {
  for_each      = toset(var.vm_names)
  project       = var.project_id
  zone          = var.zone
  instance_name = each.value
  role          = "roles/compute.viewer"
  member        = "serviceAccount:${google_service_account.developer.email}"
}

resource "google_storage_bucket_iam_member" "developer_bucket" {
  bucket = var.dev_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.developer.email}"
}

# Admin: manage the VMs, bucket, Cloud Run service and key ring (AWS: AdminPolicy)
resource "google_compute_instance_iam_member" "admin_vms" {
  for_each      = toset(var.vm_names)
  project       = var.project_id
  zone          = var.zone
  instance_name = each.value
  role          = "roles/compute.instanceAdmin.v1"
  member        = "serviceAccount:${google_service_account.admin.email}"
}

resource "google_storage_bucket_iam_member" "admin_bucket" {
  bucket = var.dev_bucket_name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.admin.email}"
}

resource "google_cloud_run_v2_service_iam_member" "admin_run" {
  project  = var.project_id
  location = var.region
  name     = var.cloud_run_service_name
  role     = "roles/run.admin"
  member   = "serviceAccount:${google_service_account.admin.email}"
}

resource "google_kms_key_ring_iam_member" "admin_kms" {
  key_ring_id = var.key_ring_id
  role        = "roles/cloudkms.admin"
  member      = "serviceAccount:${google_service_account.admin.email}"
}

# Admin may attach the VM and Cloud Run identities (AWS: iam:PassRole)
resource "google_service_account_iam_member" "admin_act_as" {
  for_each = {
    vm       = google_service_account.vm.name
    cloudrun = google_service_account.cloudrun.name
  }
  service_account_id = each.value
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.admin.email}"
}
