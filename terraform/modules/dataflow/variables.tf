variable "project_id" { 
    type        = string
#    default     = ""
    description = "The project id this module will be deployed to"
}

variable "region" { 
    type        = string 
    default     = "us-east1"
    description = "The region this module will be deployed to"
}

variable "dataflow_runner_sa_name" {
    type        = string
#    default     = ""
    description = "The name for the service account the dataflow runs under"
}

variable "dataflow_launcher_sa_name" {
    type        = string
#    default     = ""
    description = "The name for the service account that launches the dataflow job"
}

variable "staging_bucket_name" {
    type        = string
#    default     = ""
    description = "The bucket containing other files needed for running the dataflow job"
}

variable "ingestion_bucket_name" {
    type        = string
#    default     = ""
    description = "The raw bucket for the batch dataflow ingestion to pull from"
}

variable "pubsub_subscription_name" {
    type        = string
#    default     = ""
    description = "The pubsub subscription name for the dataflow ingestion to pull from"
}

variable "pubsub_topic_name" {
    type        = string
#    default     = ""
    description = "The pubsub topic name for the dataflow ingestion to pull from"
}

variable "bigquery_dataset_id" {
    type        = string
    default     = ""
    description = ""
}