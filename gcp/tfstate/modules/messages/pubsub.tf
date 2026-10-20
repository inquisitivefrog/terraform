# modules/messages/pubsub.tf
# GCP counterpart of aws/tfstate/modules/messages/sns.tf
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic

# Topics are project-wide (SNS topics are per region), so the name carries env.
# No subscription, as with the SNS topic; retry policy lives on subscriptions.
resource "google_pubsub_topic" "logging" {
  name         = "logging-topic-${var.environment}"
  project      = var.project_id
  kms_key_name = var.pubsub_logging_key_id

  message_storage_policy {
    allowed_persistence_regions = [var.region]
  }

  labels = {
    environment = var.environment
  }
}

# Lets Cloud Storage publish bucket notifications (AWS: AllowS3Publish)
resource "google_pubsub_topic_iam_member" "allow_gcs" {
  project = var.project_id
  topic   = google_pubsub_topic.logging.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.gcs_service_agent}"
}
