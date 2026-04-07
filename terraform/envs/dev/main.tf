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
    null = {
      source = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}

#####################################################################
# Get the project information, so we only need to worry about the project_id
#####################################################################
data "google_project" "project" {
  project_id = var.project_id
}

#####################################################################
# Artifact Repository
#####################################################################
module "artifact-repository" {
  source = "../../modules/artifact-repository/"

  # The variables expected by the module
  project          = local.project
  region           = var.region
  python           = local.python
  github_org       = var.github_org
  github_repo      = var.github_repo
  cicd_runner      = local.cicd_sa
  cicd_workload_id = var.cicd_workload_id
  repository_id    = var.repository_id
}

#####################################################################
# The mock data generator
#####################################################################
module "aeo_mock_generator" {
  source = "../../modules/cloud-run-functions/mock-generator"
  # The variables defined in the modules/cloud-run-functions/mock-generator module
  project               = local.project
  region                = var.region
  function_name         = var.generator_name
  bootstrap_sa          = local.bootstrap_sa
  sa_name               = var.generator_sa_name

  pubsub_details       = local.pubsub_details_final
  raw_bucket_name       = module.storage.raw_landing_name

  depends_on = [google_project_service.required]
}

#####################################################################
# The storage needed by the application
#####################################################################
module "storage" {
    source = "../../modules/storage/"

    project          = local.project
    region           = var.region
    storage_class    = var.storage_class
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

  pubsub_details = local.pubsub_details

  depends_on = [google_project_service.required]
}

#####################################################################
# The Dataflow module to define creating the ingestion mechanism
#####################################################################
module "dataflow" {
  source = "../../modules/dataflow"

  project                   = local.project
  region                    = var.region 
  dataflow_runner_sa_name   = var.dataflow_runner_sa_name
  dataflow_launcher_sa_name = var.dataflow_launcher_sa_name
  staging_bucket_name       = module.storage.dataflow_staging
  ingestion_bucket_name     = module.storage.raw_landing_name
  pubsub_details            = local.pubsub_details_final
  bigquery_datasets         = local.bigquery_details

  depends_on = [google_project_service.required]
}

#####################################################################
# BigQuery
#####################################################################
module "bigquery" {
  source = "../../modules/bigquery"

  project                   = local.project
  region                    = var.region
  environment               = var.environment
#  human_analyst_group      = var.analyst_group
  runtime_sa_name           = var.runtime_sa_name
#  deployer_member          = var.bigquery_deployer

  bigquery_details = local.bigquery_bootstrap

  depends_on = [
    google_project_iam_member.terraform_bigquery_creator, 
    google_project_service.required
  ]
}

#####################################################################
# Composer
#####################################################################
#module "composer" {
#  source = "../../modules/composer"
#
#  project               = local.project
#  region                   = var.region
#  composer_env_name        = var.composer_env_name
#  bootstrap_sa             = local.bootstrap_sa
#  composer_sa_name         = var.composer_sa_name
#  image_version            = var.image_version
#  python                   = local.python
#  env_variables            = local.env_variables
#  airflow_config_overrides = var.airflow_config_overrides
#  labels                   = local.labels
#
#  depends_on = [google_project_service.required]
#}