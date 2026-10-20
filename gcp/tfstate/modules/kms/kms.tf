# modules/kms/kms.tf
# GCP counterpart of aws/tfstate/modules/kms/kms.tf
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key

# GCP never deletes key rings or keys; terraform destroy only destroys key
# versions and forgets the key. A fixed name (AWS: alias/tfstate-{env}) would
# collide on the next rebuild, so the key ring carries the random suffix.
resource "google_kms_key_ring" "tfstate" {
  name     = "tfstate-${var.env}-${var.random_suffix}"
  project  = var.project_id
  location = var.region
}

resource "google_kms_crypto_key" "state_bucket_key" {
  name            = "state-bucket-key"
  key_ring        = google_kms_key_ring.tfstate.id
  rotation_period = "7776000s" # 90 days
  labels = {
    environment = var.env
  }
}

resource "google_kms_crypto_key" "pubsub_logging_key" {
  name                       = "pubsub-logging-key"
  key_ring                   = google_kms_key_ring.tfstate.id
  rotation_period            = "7776000s"
  destroy_scheduled_duration = "604800s" # 7 days, like the AWS SNS key
  labels = {
    environment = var.env
  }
}

# Service agents that encrypt on our behalf (AWS: the key policy statements)
data "google_project" "this" {
  project_id = var.project_id
}

data "google_storage_project_service_account" "gcs" {
  project = var.project_id
}

resource "google_kms_crypto_key_iam_member" "gcs_state_bucket_key" {
  crypto_key_id = google_kms_crypto_key.state_bucket_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}

resource "google_kms_crypto_key_iam_member" "pubsub_logging_key" {
  crypto_key_id = google_kms_crypto_key.pubsub_logging_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}
