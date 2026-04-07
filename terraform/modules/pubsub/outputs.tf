output "pubsub_topic_id" {
    value = google_pubsub_topic.ingestion_gateway.name
}

output "pubsub_browse_event_subscription" {
    value = google_pubsub_subscription.browse_event_subscription.name
}

output "pubsub_cart_event_subscription" {
    value = google_pubsub_subscription.cart_event_subscription.name
}

output "pubsub_commerce_event_subscription" {
    value = google_pubsub_subscription.commerce_event_subscription.name
}

output "pubsub_return_event_subscription" {
    value = google_pubsub_subscription.return_event_subscription.name
}

output "pubsub_inventory_event_subscription" {
    value = google_pubsub_subscription.inventory_event_subscription.name
}