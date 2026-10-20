# modules/identity/service_accounts.tf
# GCP counterpart of aws/single_instance/modules/identity
# IAM is per project and dev and prod share one, so every name carries env;
# each env creates its own identities (AWS: dev created them, prod looked
# them up). Terraform can't create Google user accounts or groups without
# Cloud Identity admin, so the sre and dba users are service accounts that
# can impersonate the admin account (AWS: operations group + AssumeRole).

resource "google_service_account" "vm" { # AWS: EC2Role + EC2Profile
  account_id   = "vm-${var.env}"
  project      = var.project_id
  display_name = "VMs (${var.env})"
}

resource "google_service_account" "gke_node" { # AWS: eks-node-role
  account_id   = "gke-node-${var.env}"
  project      = var.project_id
  display_name = "GKE nodes (${var.env})"
}

resource "google_service_account" "cloudrun" { # AWS: ecsTaskExecutionRole
  account_id   = "cloudrun-${var.env}"
  project      = var.project_id
  display_name = "Cloud Run nginx (${var.env})"
}

resource "google_service_account" "developer" { # AWS: Developer role
  account_id   = "developer-${var.env}"
  project      = var.project_id
  display_name = "Developer (${var.env})"
}

resource "google_service_account" "admin" { # AWS: Admin role
  account_id   = "admin-${var.env}"
  project      = var.project_id
  display_name = "Admin (${var.env})"
}

resource "google_service_account" "operators" { # AWS: IAM users sre, dba
  for_each     = toset(["sre", "dba"])
  account_id   = "${each.key}-${var.env}"
  project      = var.project_id
  display_name = "${each.key} operator (${var.env})"
}

# sre and dba may act as admin (AWS: AssumeAdminRolePolicy)
resource "google_service_account_iam_member" "operators_assume_admin" {
  for_each           = google_service_account.operators
  service_account_id = google_service_account.admin.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${each.value.email}"
}

# --- Project roles ---

locals {
  project_roles = {
    vm_log       = { sa = google_service_account.vm.email, role = "roles/logging.logWriter" }
    vm_metric    = { sa = google_service_account.vm.email, role = "roles/monitoring.metricWriter" }
    vm_gke       = { sa = google_service_account.vm.email, role = "roles/container.clusterViewer" } # get-credentials; RBAC grants cluster-admin
    node_log     = { sa = google_service_account.gke_node.email, role = "roles/logging.logWriter" }
    node_metric  = { sa = google_service_account.gke_node.email, role = "roles/monitoring.metricWriter" }
    node_viewer  = { sa = google_service_account.gke_node.email, role = "roles/monitoring.viewer" }
    node_meta    = { sa = google_service_account.gke_node.email, role = "roles/stackdriver.resourceMetadata.writer" }
    node_ar      = { sa = google_service_account.gke_node.email, role = "roles/artifactregistry.reader" }
    admin_redis  = { sa = google_service_account.admin.email, role = "roles/redis.admin" } # no per-instance IAM for Memorystore
    admin_pubsub = { sa = google_service_account.admin.email, role = "roles/pubsub.editor" }
  }
}

resource "google_project_iam_member" "roles" {
  for_each = local.project_roles
  project  = var.project_id
  role     = each.value.role
  member   = "serviceAccount:${each.value.sa}"
}
