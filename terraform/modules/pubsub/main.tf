resource "google_pubsub_topic" "ingestion_gateway" {
  name = var.pubsub_details.topic_name
}

resource "google_pubsub_subscription" "browse_event_subscription" {
  name  = var.pubsub_details.browse_event
  topic = google_pubsub_topic.ingestion_gateway.name

  ack_deadline_seconds = 10

  depends_on = [google_pubsub_topic.ingestion_gateway]
}

resource "google_pubsub_subscription" "cart_event_subscription" {
  name  = var.pubsub_details.cart_event
  topic = google_pubsub_topic.ingestion_gateway.name

  ack_deadline_seconds = 10

  depends_on = [google_pubsub_topic.ingestion_gateway]
}

resource "google_pubsub_subscription" "commerce_event_subscription" {
  name  = var.pubsub_details.commerce_event
  topic = google_pubsub_topic.ingestion_gateway.name

  ack_deadline_seconds = 10

  depends_on = [google_pubsub_topic.ingestion_gateway]
}

resource "google_pubsub_subscription" "return_event_subscription" {
  name  = var.pubsub_details.return_event
  topic = google_pubsub_topic.ingestion_gateway.name

  ack_deadline_seconds = 10

  depends_on = [google_pubsub_topic.ingestion_gateway]
}

resource "google_pubsub_subscription" "inventory_event_subscription" {
  name  = var.pubsub_details.inventory_event
  topic = google_pubsub_topic.ingestion_gateway.name

  ack_deadline_seconds = 10

  depends_on = [google_pubsub_topic.ingestion_gateway]
}