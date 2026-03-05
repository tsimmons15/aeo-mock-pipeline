terraform {
  backend "gcs" {
    bucket = "aeo-tf-state-dev"
    prefix = "state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

#####################################################################
# The mock data generator
#####################################################################
module "aeo_mock_generator" {
  source = "../../modules/cloud-run-functions/mock-generator"
  # The variables defined in the modules/cloud-run-functions/mock-generator module
  project_id            = var.project_id
  region                = var.region
  function_name         = var.generator_name
  sa_name               = var.sa_name

  pubsub_topic_id       = module.pubsub.pubsub_topic
  raw_bucket_name       = module.storage.raw_landing_name
}

#####################################################################
# The storage needed by the application
#####################################################################
module "storage" {
    source = "../../modules/storage/"

    project_id = var.project_id
    region = var.region
    storage_class = var.storage_class
    retention_period = var.retention_period
    raw_landing_name = var.raw_bucket_name
}

#####################################################################
# The PubSub module to define creating the PubSub topics/subscriptions
#####################################################################
module "pubsub" {
  source = "../../modules/pubsub"

  pubsub_topic_name = var.pubsub_topic_name
  pubsub_subscriber_name = var.pubsub_subscriber_name
}