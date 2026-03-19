terraform {
  required_version = ">= 1.6.0"
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
  function_builder      = var.builder_sa
  sa_name               = var.generator_sa_name

  pubsub_topic_id       = module.pubsub.pubsub_topic
  raw_bucket_name       = module.storage.raw_landing_name

  depends_on = [google_project_service.required]
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
    dataflow_staging = var.dataflow_staging
    raw_landing_name = var.raw_bucket_name

    depends_on = [google_project_service.required]
}

#####################################################################
# The PubSub module to define creating the PubSub topics/subscriptions
#####################################################################
module "pubsub" {
  source = "../../modules/pubsub"

  pubsub_topic_name = var.pubsub_topic_name
  pubsub_subscriber_name = var.pubsub_subscriber_name

  depends_on = [google_project_service.required]
}

#####################################################################
# The PubSub module to define creating the PubSub topics/subscriptions
#####################################################################
module "dataflow" {
  source = "../../modules/dataflow"

  project_id                = var.project_id
  region                    = var.region 
  dataflow_runner_sa_name   = var.dataflow_runner_sa_name
  dataflow_launcher_sa_name = var.dataflow_launcher_sa_name
  staging_bucket_name       = module.storage.dataflow_staging
  ingestion_bucket_name     = module.storage.raw_landing_name
  pubsub_subscription_name  = module.pubsub.pubsub_ingestion_sub
  pubsub_topic_name         = module.pubsub.pubsub_topic
  bigquery_dataset_id       = ""
}

#####################################################################
# BigQuery
#####################################################################
module "bigquery" {
  source = "../../modules/bigquery"

  project_id          = var.project_id
  region              = var.region
  dataset_id          = var.dataset_id
  dataset_location    = var.dataset_location
  environment         = var.environment
#  human_analyst_group = var.analyst_group
  runtime_sa_name     = var.runtime_sa_name
#  deployer_member     = var.bigquery_deployer

  depends_on = [google_project_iam_member.terraform_bigquery_creator]
}