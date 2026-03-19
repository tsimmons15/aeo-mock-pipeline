#####################################################################
# Project specific variables
#####################################################################
variable "project_id" {
  type        = string
  description = "The project id for the dev environment."
}

variable "region" {
  type        = string
  description = "The region resources will be deployed in."
}

variable "environment" {
  type        = string
#  default     = ""
  description = ""
}

#####################################################################
# Bootstrap variables
#####################################################################
variable "builder_sa" {
  type        = string
  description = "The service account specified to build the project."
}

#####################################################################
# Mock generator variables
#####################################################################
variable "generator_name" {
  type        = string
  description = "The name the Cloud Run function will be given."
}

variable "generator_sa_name" {
  type        = string
  description = "The service account name that the function will run as."
}

#####################################################################
# PubSub variables
#####################################################################
variable "pubsub_topic_name" {
  type        = string
  description = "The Pub/Sub topic name."
}

variable "pubsub_subscriber_name" {
  type        = string
  description = "The Pub/Sub subscription name."
}

#####################################################################
# Storage variables
#####################################################################
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


#####################################################################
# Dataflow variables
#####################################################################
variable "dataflow_staging" {
  type        = string
  description = "The dataflow staging storage bucket name."
}

variable "dataflow_runner_sa_name" {
  type        = string
  description = "The dataflow runner account"
}

variable "dataflow_launcher_sa_name" {
  type        = string
  description = "The dataflow launcher account"
}

#####################################################################
# BigQuery
#####################################################################
variable "dataset_id" {
  type        = string
#  default     = ""
  description = ""
}

variable "dataset_location" {
  type        = string
#  default     = ""
  description = ""
}

variable "runtime_sa_name" {
  type        = string
#  default     = ""
  description = ""
}