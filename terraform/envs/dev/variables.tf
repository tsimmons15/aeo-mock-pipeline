variable "project_id" {
  type        = string
  description = "The project id for the dev environment."
}

variable "region" {
  type        = string
  description = "The region resources will be deployed in."
}

variable "builder_sa" {
  type        = string
  description = "The service account specified to build the project."
}

variable "generator_name" {
  type        = string
  description = "The name the Cloud Run function will be given."
}

variable "sa_name" {
  type        = string
  description = "The service account name that the function will run as."
}

variable "pubsub_topic_name" {
  type        = string
  description = "The Pub/Sub topic name."
}

variable "pubsub_subscriber_name" {
  type        = string
  description = "The Pub/Sub subscription name."
}

variable "dataflow_storage" {
  type        = string
  description = "The dataflow storage bucket name."
}

variable "raw_bucket_name" {
  type        = string
  description = "The raw landing bucket name."
}

variable "storage_class" {
  type        = string
  description = "The storage class for GCS buckets."
}

variable "retention_period" {
  type        = number
  description = "Soft delete retention period in seconds."
}