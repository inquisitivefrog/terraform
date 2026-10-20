# modules/storage/gcs_dev_bucket.tf
# GCP counterpart of aws/single_instance/modules/storage/s3_dev_bucket.tf

resource "google_storage_bucket" "dev_bucket" {
  name          = "bluedragon-dev-bucket-${var.random_suffix}"
  project       = var.project_id
  location      = upper(var.region)
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = var.messages_key_id
  }

  logging {
    log_bucket        = google_storage_bucket.log_bucket.name
    log_object_prefix = "logs/"
  }

  lifecycle_rule {
    condition {
      age            = 90
      matches_prefix = ["logs/"]
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
    name        = "bluedragon-dev-bucket"
  }

  depends_on = [google_storage_bucket_iam_member.log_bucket_writer]
}

resource "google_storage_notification" "dev_bucket" {
  bucket             = google_storage_bucket.dev_bucket.name
  topic              = var.example_topic_id
  payload_format     = "JSON_API_V1"
  event_types        = ["OBJECT_FINALIZE"]
  object_name_prefix = "logs/"
}
