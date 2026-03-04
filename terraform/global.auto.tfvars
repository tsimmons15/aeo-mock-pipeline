#####################################################################
# General project values
#####################################################################
region           = "us-east1"

#####################################################################
# Storage bucket related values
#####################################################################
raw_bucket_name = "aeo-raw-landing-data"
dataflow_storage = "aeo-dataflow-storage"
storage_class = "COLDLINE"
retention_period = 0 # Disables soft delete

#####################################################################
# PubSub related values
#####################################################################
# Used for Mock generator
pubsub_topic_name  = "aeo-rt-events"
pubsub_subscriber_name = "aeo-rt-events-sub"


#####################################################################
# Mock generator values
#####################################################################
generator_name   = "aeo-mock-generator"
sa_name          = "mock-generator"
