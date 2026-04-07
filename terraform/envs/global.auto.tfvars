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
pubsub_topic_name                   = "aeo-rt-events"
#pubsub_subscriber_name             = "aeo-rt-events-sub"
pubsub_browse_event_subscription    = "aeo-events-browse-sub"
pubsub_cart_event_subscription      = "aeo-events-cart-sub"
pubsub_commerce_event_subscription  = "aeo-events-commerce-sub"
pubsub_return_event_subscription    = "aeo-events-returns-sub"
pubsub_inventory_event_subscription = "aeo-events-inventory-sub"


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
staging_dataset         = "retail_staging"
core_dataset            = "retail"
merchandising_mart      = "retail_mart_merchandising"
demography_mart         = "retail_mart_customer_demography"
data_quality_results    = "retail_data_quality"
stg_orders              = "stg_orders"
stg_returns             = "stg_returns"
stg_inventory_snapshots = "stg_inventory_snapshots"
stg_product             = "stg_product"
dataset_location        = "US"
#human_analyst_group    = 
runtime_sa_name         = "bigquery-runner"


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