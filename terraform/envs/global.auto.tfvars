#####################################################################
# General project values
#####################################################################
region                 = "us-east1"
cicd_sa_name           = "cicd-runner"

#####################################################################
# Storage bucket related values
#####################################################################
raw_bucket_name        = "aeo-raw-landing-data"
dataflow_staging       = "aeo-dataflow-staging"
storage_class          = "COLDLINE"
retention_period       = 0 # Disables soft delete

#####################################################################
# PubSub related values
#####################################################################
# Used for Mock generator
pubsub_topic_name      = "aeo-rt-events"
pubsub_subscriber_name = "aeo-rt-events-sub"


#####################################################################
# Mock generator values
#####################################################################
generator_name         = "aeo-mock-generator"
generator_sa_name      = "mock-generator"


#####################################################################
# Dataflow values
#####################################################################
dataflow_runner_sa_name       = "dataflow-runner"
dataflow_launcher_sa_name     = "dataflow-launcher"


#####################################################################
# BigQuery values
#####################################################################
raw_dataset_id          = "aeo_demo_raw"
core_dataset_id         = "aeo_demo_core"
analytics_dataset_id    = "aeo_demo_analytics_mart"
dataset_location    = "US"
#human_analyst_group = 
runtime_sa_name     = "bigquery-runner"

#####################################################################
# Composer values
#####################################################################

env_variables = {
  DATASET     = "analytics"
  RAW_BUCKET  = "my-raw-bucket"
}

airflow_config_overrides = {
  "core-dags_are_paused_at_creation" = "true"
  "scheduler-catchup_by_default"     = "false"
  "webserver-dag_default_view"       = "grid"
}

python_version = "3.11"
pypi_packages = {
    "requests"                        = ">=2.31.0"
}

image_version = "composer-3-airflow-2.10.5-build.29"

labels = {
  managed_by = "terraform"
  team       = "data-eng"
}

#####################################################################
# Artifact Registry variables
#####################################################################
repository_id = "aeo-python-repo"
cicd_workload_id = "cicd-deploy-pool"
