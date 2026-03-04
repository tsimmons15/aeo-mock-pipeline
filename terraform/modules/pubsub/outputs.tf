output "pubsub_topic" {
    value = google_pubsub_topic.ingestion_gateway.name
}

output "pubsub_ingestion_sub" {
    value = google_pubsub_subscription.ingestion_sub.name
}