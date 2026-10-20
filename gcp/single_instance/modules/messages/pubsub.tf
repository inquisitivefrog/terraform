# modules/messages/pubsub.tf
# GCP counterpart of aws/single_instance/modules/messages/sns.tf
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic

# AWS: example-topic, receives bucket notifications
resource "google_pubsub_topic" "example" {
  name         = "example-topic-${var.env}"
  project      = var.project_id
  kms_key_name = var.messages_key_id

  message_storage_policy {
    allowed_persistence_regions = [var.region]
  }

  labels = {
    environment = var.env
  }
}

# Lets Cloud Storage publish bucket notifications (AWS: example_policy)
resource "google_pubsub_topic_iam_member" "example_allow_gcs" {
  project = var.project_id
  topic   = google_pubsub_topic.example.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.gcs_service_agent}"
}

# AWS: https subscription with a linear 20s retry policy. Pub/Sub keeps
# retrying until retention runs out, so retention bounds the retries.
resource "google_pubsub_subscription" "example" {
  name                       = "example-push-${var.env}"
  project                    = var.project_id
  topic                      = google_pubsub_topic.example.id
  message_retention_duration = "600s"

  push_config {
    push_endpoint = "https://example.com/sns-notification"
  }

  retry_policy {
    minimum_backoff = "20s"
    maximum_backoff = "20s"
  }
}

# AWS: custom-topic.fifo. Pub/Sub orders and deduplicates on the
# subscription: message ordering (FIFO) + exactly-once delivery.
resource "google_pubsub_topic" "custom" {
  name         = "custom-topic-${var.env}"
  project      = var.project_id
  kms_key_name = var.messages_key_id

  message_storage_policy {
    allowed_persistence_regions = [var.region]
  }

  labels = {
    environment = var.env
  }
}

resource "google_pubsub_subscription" "custom" {
  name                         = "custom-ordered-${var.env}"
  project                      = var.project_id
  topic                        = google_pubsub_topic.custom.id
  enable_message_ordering      = true
  enable_exactly_once_delivery = true
}
