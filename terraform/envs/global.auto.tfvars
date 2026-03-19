#####################################################################
# General project values
#####################################################################
region                 = "us-east1"

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
# BigQuery
#####################################################################
dataset_id          = "aeo_demo_bronze"
dataset_location    = "US"
#human_analyst_group = 
runtime_sa_name     = "bigquery-runner"