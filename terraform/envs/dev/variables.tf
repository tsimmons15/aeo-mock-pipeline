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

variable "cicd_sa_name" {
  type        = string
#  default     = ""
  description = ""
}

variable "python_version" {
  type        = string
#  default     = ""
  description = "The version of Python the project is pegged to"
}


#####################################################################
# Artifact Repository variables
#####################################################################
variable "github_repo" {
  type        = string
#  default     = ""
  description = ""
}

variable "github_org" {
  type        = string
#  default     = ""
  description = ""
}

variable "repository_id" {
    type        = string
#   default     = ""
    description = ""
}

variable "cicd_workload_id" {
    type = string
#   default = ""
    description = "The auth pool used for this workload pool."
}

#####################################################################
# Bootstrap variables
#####################################################################
variable "bootstrap_sa_name" {
  type        = string
#  default     = ""
  description = "The name given to the bootstrap service account. Used for building services."
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

variable "pubsub_browse_event_subscription" {
  type        = string
  description = "The Pub/Sub browse event subscription name."
}
variable "pubsub_cart_event_subscription" {
  type        = string
  description = "The Pub/Sub cart event subscription name."
}
variable "pubsub_commerce_event_subscription" {
  type        = string
  description = "The Pub/Sub commerce event subscription name."
}
variable "pubsub_return_event_subscription" {
  type        = string
  description = "The Pub/Sub return event subscription name."
}
variable "pubsub_inventory_event_subscription" {
  type        = string
  description = "The Pub/Sub inventory event subscription name."
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

variable "staging_dataset" {
  type        = string
#  default     = ""
  description = ""
}

variable "core_dataset" {
  type        = string
#  default     = ""
  description = ""
}

variable "merchandising_mart" {
  type        = string
#  default     = ""
  description = ""
}

variable "demography_mart" {
  type        = string
#  default     = ""
  description = ""
}

variable "data_quality_results" {
  type        = string
#  default     = ""
  description = ""
}

variable "stg_orders" {
  type        = string
#  default     = ""
  description = ""
}

variable "stg_returns" {
  type        = string
#  default     = ""
  description = ""
}

variable "stg_inventory_snapshots" {
  type        = string
#  default     = ""
  description = ""
}

variable "stg_product" {
  type        = string
#  default     = ""
  description = ""
}

#####################################################################
# Composer variables
#####################################################################
variable "composer_env_name" {
  type        = string
#  default     = "composer-data-platform"
  description = ""
}

variable "composer_sa_name" {
  type        = string
#  default     = "composer-runtime-sa"
  description = ""
}

variable "image_version" {
  type        = string
#  default     = "composer-3-airflow-2.10.5-build.29"
  description = ""
}

variable "pypi_packages" {
  type        = map(string)
#  default     = {
#       "apache-airflow-providers-google" = ""
#       "pandas"                          = ">=2.2.0"
#       "requests"                        = ">=2.31.0"
#  }
  description = ""
}

variable "env_variables" {
  type        = map(string)
#  default     = {
#       ENV        = "dev"
#       PROJECT_ID = "replace-me"
#  }
  description = ""
}

variable "airflow_config_overrides" {
  type        = map(string)
#  default     = {
#        "core-dags_are_paused_at_creation" = "true"
#        "scheduler-catchup_by_default"     = "false"
#   }
  description = ""
}

variable "labels" {
  type        = map(string)
#  default     = {
#       managed_by = "terraform"
#       platform   = "composer"
#  }
  description = ""
}
