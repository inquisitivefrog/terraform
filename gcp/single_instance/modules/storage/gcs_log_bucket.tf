# modules/storage/gcs_log_bucket.tf
# GCP counterpart of aws/single_instance/modules/storage/s3_log_bucket.tf
# AWS also logged this bucket to itself ("self-logs/"); that loop is left out.

resource "google_storage_bucket" "log_bucket" {
  name          = "bluedragon-log-bucket-${var.random_suffix}"
  project       = var.project_id
  location      = upper(var.region)
  force_destroy = true

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = var.messages_key_id
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }

  labels = {
    environment = var.env
    name        = "bluedragon-log-bucket"
  }
}

# Usage logs are written by this Google group (AWS: logging.s3.amazonaws.com)
resource "google_storage_bucket_iam_member" "log_bucket_writer" {
  bucket = google_storage_bucket.log_bucket.name
  role   = "roles/storage.objectCreator"
  member = "group:cloud-storage-analytics@google.com"
}

resource "google_storage_notification" "log_bucket" {
  bucket             = google_storage_bucket.log_bucket.name
  topic              = var.example_topic_id
  payload_format     = "JSON_API_V1"
  event_types        = ["OBJECT_FINALIZE"]
  object_name_prefix = "logs/"
}
