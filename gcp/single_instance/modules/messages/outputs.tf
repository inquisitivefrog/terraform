# modules/messages/outputs.tf

output "custom_topic_id" {
  value = google_pubsub_topic.custom.id
}

output "example_topic_id" {
  value      = google_pubsub_topic.example.id
  depends_on = [google_pubsub_topic_iam_member.example_allow_gcs] # notifications need the grant first
}
