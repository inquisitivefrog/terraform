# modules/messages/outputs.tf

output "pubsub_topic_logging_id" {
  description = "ID of the Pub/Sub logging topic"
  value       = google_pubsub_topic.logging.id
  depends_on  = [google_pubsub_topic_iam_member.allow_gcs] # notifications need the grant first
}
