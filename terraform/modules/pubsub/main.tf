resource "google_pubsub_topic" "ingestion_gateway" {
  name = var.pubsub_topic_name
}

resource "google_pubsub_subscription" "ingestion_sub" {
  name  = var.pubsub_subscriber_name
  topic = google_pubsub_topic.ingestion_gateway.name

  ack_deadline_seconds = 10
}
