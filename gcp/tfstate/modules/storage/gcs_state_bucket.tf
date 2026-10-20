# modules/storage/gcs_state_bucket.tf
# GCP counterpart of aws/tfstate/modules/storage/s3_state_bucket.tf
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_notification

locals {
  state_bucket_name = var.random_suffix != "" ? "${var.tfstate_bucket}-${var.random_suffix}" : var.tfstate_bucket
  log_bucket_name   = var.random_suffix != "" ? "${var.tfstate_bucket}-logs-${var.random_suffix}" : "${var.tfstate_bucket}-logs"

  # GCP label values allow only lowercase letters, digits, '-' and '_'
  labels = {
    employer    = replace(lower(var.employer), "/[^a-z0-9_-]/", "-")
    environment = var.env
  }
}

resource "google_storage_bucket" "state_bucket" {
  name          = local.state_bucket_name
  project       = var.project_id
  location      = upper(var.region)
  force_destroy = false
  labels        = local.labels

  # Replaces S3 ACLs, ownership controls and the public access block
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  # Noncurrent versions: Coldline after 30 days (S3: Glacier), deleted after 365
  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 30
      with_state                 = "ARCHIVED"
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 365
      with_state                 = "ARCHIVED"
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

  # null key = Google-managed encryption (bootstrap); otherwise CMEK
  dynamic "encryption" {
    for_each = var.state_bucket_key_id != null ? [1] : []
    content {
      default_kms_key_name = var.state_bucket_key_id
    }
  }

  logging {
    log_bucket        = google_storage_bucket.state_log_bucket.name
    log_object_prefix = "state-logs/"
  }

  depends_on = [google_storage_bucket_iam_member.state_log_bucket_writer]
}

# GCS can filter only by prefix, not suffix (S3 used ".tfstate"), so every
# object written here notifies, including the backend's .tflock files.
resource "google_storage_notification" "state_bucket_notification" {
  count          = var.enable_notifications ? 1 : 0
  bucket         = google_storage_bucket.state_bucket.name
  topic          = var.pubsub_topic_logging_id
  payload_format = "JSON_API_V1"
  event_types    = ["OBJECT_FINALIZE"]
}
