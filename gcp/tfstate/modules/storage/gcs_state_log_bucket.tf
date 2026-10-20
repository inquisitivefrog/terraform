# modules/storage/gcs_state_log_bucket.tf
# GCP counterpart of aws/tfstate/modules/storage/s3_state_log_bucket.tf
# https://cloud.google.com/storage/docs/access-logs

resource "google_storage_bucket" "state_log_bucket" {
  name          = local.log_bucket_name
  project       = var.project_id
  location      = upper(var.region)
  force_destroy = false
  labels        = merge(local.labels, { purpose = "logs" })

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Google-managed encryption, like the S3 log bucket's SSE-S3
  versioning {
    enabled = true
  }
}

# Usage logs are written by this Google group (S3: logging.s3.amazonaws.com)
resource "google_storage_bucket_iam_member" "state_log_bucket_writer" {
  bucket = google_storage_bucket.state_log_bucket.name
  role   = "roles/storage.objectCreator"
  member = "group:cloud-storage-analytics@google.com"
}

resource "google_storage_notification" "state_log_bucket_notification" {
  count              = var.enable_notifications ? 1 : 0
  bucket             = google_storage_bucket.state_log_bucket.name
  topic              = var.pubsub_topic_logging_id
  payload_format     = "JSON_API_V1"
  event_types        = ["OBJECT_FINALIZE"]
  object_name_prefix = "state-logs/"
}
