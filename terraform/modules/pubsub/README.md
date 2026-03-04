# Pub/Sub Ingestion Module

This module creates a Google Cloud Pub/Sub topic and a pull subscription for an ingestion gateway, and exposes their names as outputs.

## Resources

- `google_pubsub_topic.ingestion_gateway`  
  - Pub/Sub topic used as the ingestion entry point.
- `google_pubsub_subscription.ingestion_sub`  
  - Pull subscription attached to the ingestion topic.
  - Uses `ack_deadline_seconds = 10` for fast redelivery of unacked messages.

## Inputs

| Name                   | Type     | Description                                        | Required |
|------------------------|----------|----------------------------------------------------|----------|
| `pubsub_topic_name`    | string   | The topic name for the ingestion Pub/Sub.         | yes      |
| `pubsub_subscriber_name` | string | The subscriber name for the ingestion Pub/Sub topic. | yes   |

## Outputs

| Name                 | Description                                   |
|----------------------|-----------------------------------------------|
| `pubsub_topic`       | The name of the ingestion Pub/Sub topic.     |
| `pubsub_ingestion_sub` | The name of the ingestion pull subscription. |