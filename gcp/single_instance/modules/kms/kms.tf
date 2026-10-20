# modules/kms/kms.tf
# GCP counterpart of aws/single_instance/modules/kms
# Key rings can't be deleted, so the name carries the random suffix.
# The VPC flow-logs key has no counterpart: flow logs go to Cloud Logging,
# whose CMEK is a project-wide setting rather than a per-log key.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key

resource "google_kms_key_ring" "main" {
  name     = "single-instance-${var.env}-${var.random_suffix}"
  project  = var.project_id
  location = var.region
}

# AWS: eks_key (EKS secrets encryption)
resource "google_kms_crypto_key" "gke_key" {
  name                       = "gke-secrets-key"
  key_ring                   = google_kms_key_ring.main.id
  rotation_period            = "7776000s" # 90 days
  destroy_scheduled_duration = "604800s"  # 7 days
}

# AWS: sns_custom_key (SNS topics and S3 buckets)
resource "google_kms_crypto_key" "messages_key" {
  name                       = "messages-key"
  key_ring                   = google_kms_key_ring.main.id
  rotation_period            = "7776000s"
  destroy_scheduled_duration = "604800s"
}

# AWS: symmetric_key (example, administered by the admin user)
resource "google_kms_crypto_key" "symmetric_key" {
  name                       = "symmetric-key"
  key_ring                   = google_kms_key_ring.main.id
  rotation_period            = "7776000s"
  destroy_scheduled_duration = "1728000s" # 20 days
}

# AWS: asymmetric_key (RSA-3072 sign/verify, no rotation)
resource "google_kms_crypto_key" "asymmetric_key" {
  name                       = "asymmetric-key"
  key_ring                   = google_kms_key_ring.main.id
  purpose                    = "ASYMMETRIC_SIGN"
  destroy_scheduled_duration = "604800s"

  version_template {
    algorithm = "RSA_SIGN_PKCS1_3072_SHA256"
  }
}

# --- Grants (AWS: key policy statements) ---

data "google_project" "this" {
  project_id = var.project_id
}

data "google_storage_project_service_account" "gcs" {
  project = var.project_id
}

locals {
  gke_agent    = "serviceAccount:service-${data.google_project.this.number}@container-engine-robot.iam.gserviceaccount.com"
  pubsub_agent = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  gcs_agent    = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}

resource "google_kms_crypto_key_iam_member" "gke_key" {
  crypto_key_id = google_kms_crypto_key.gke_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = local.gke_agent
}

resource "google_kms_crypto_key_iam_binding" "messages_key" {
  crypto_key_id = google_kms_crypto_key.messages_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = [local.pubsub_agent, local.gcs_agent]
}

resource "google_kms_crypto_key_iam_member" "symmetric_key_admin" {
  crypto_key_id = google_kms_crypto_key.symmetric_key.id
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${var.admin_sa_email}"
}

resource "google_kms_crypto_key_iam_member" "asymmetric_key_admin" {
  crypto_key_id = google_kms_crypto_key.asymmetric_key.id
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${var.admin_sa_email}"
}

resource "google_kms_crypto_key_iam_member" "asymmetric_key_signer" {
  crypto_key_id = google_kms_crypto_key.asymmetric_key.id
  role          = "roles/cloudkms.signerVerifier"
  member        = "serviceAccount:${var.developer_sa_email}"
}
