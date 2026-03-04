variable "pubsub_topic_name" {
    type = "string"
#    default = ""
    description = "The topic name for the ingestion pubsub"
}

variable "pubsub_subscriber_name" {
    type = "string"
#    default = ""
    description = "The subscriber name for the ingestion pubsub topic"
}