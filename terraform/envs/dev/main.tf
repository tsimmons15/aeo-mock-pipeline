#####################################################################
# The mock data generator
#####################################################################
module "aeo_mock_generator" {
  source = "../../modules/cloud_run_functions/mock_generator"
  # The variables defined in the modules/cloud_run_functions/mock_generator module
  project_id            = var.project_id
  region                = var.region
  function_name         = var.generator_name
  sa_name               = var.sa_name

  pubsub_topic_id       = module.pubsub.topic_id
  raw_bucket_name       = module.storage.raw_landing
}

#####################################################################
# The storage needed by the application
#####################################################################
module "storage" {
    source = "../../modules/storage/"

    project_id = var.project_id
    region = var.region
}