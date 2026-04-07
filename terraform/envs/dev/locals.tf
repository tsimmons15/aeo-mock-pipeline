#####################################################################
# Possibly superficial locals to package bootstrap information
# into a nice package
#####################################################################
locals {
  project = {
    id     = var.project_id
    number = data.google_project.project.number
  }
  bootstrap_sa = {
    account_id = var.bootstrap_sa_name
    name       = data.google_service_account.bootstrap.name
    email      = data.google_service_account.bootstrap.email
    unique_id  = data.google_service_account.bootstrap.unique_id
  }
  cicd_sa = {
    account_id = var.cicd_sa_name
    name       = resource.google_service_account.cicd_runner.name
    email      = resource.google_service_account.cicd_runner.email
    unique_id  = resource.google_service_account.cicd_runner.unique_id
  }
  python = {
    version = var.python_version
    packages = var.pypi_packages
  }
  
  pubsub_details = {
    topic_name      = var.pubsub_topic_name
    browse_event    = var.pubsub_browse_event_subscription
    cart_event      = var.pubsub_cart_event_subscription
    commerce_event  = var.pubsub_commerce_event_subscription
    return_event    = var.pubsub_return_event_subscription
    inventory_event = var.pubsub_inventory_event_subscription
  }
  pubsub_details_final = merge(local.pubsub_details, {topic_id = module.pubsub.pubsub_topic_id})

  bigquery_datasets = {
    retail_staging = module.bigquery.retail_staging_dataset
    core_retail = module.bigquery.retail_core_dataset
    merchandising_mart = module.bigquery.retail_mart_merchandising_dataset
    demography_mart = module.bigquery.retail_mart_customer_demography_dataset
    data_quality = module.bigquery.retail_data_quality_dataset
  }
  bigquery_tables = {
    stg_orders_id = module.bigquery.staging_orders_table
    stg_returns_id = module.bigquery.staging_returns_table
    stg_inventory_snapshots_id = module.bigquery.staging_inventory_snapshots_table
    stg_product_id = module.bigquery.staging_product_table
  }
  bigquery_dataset_bootstrap = {
    retail_staging = module.bigquery.retail_staging_dataset
    core_retail = module.bigquery.retail_core_dataset
    merchandising_mart = module.bigquery.retail_mart_merchandising_dataset
    demography_mart = module.bigquery.retail_mart_customer_demography_dataset
    data_quality = module.bigquery.retail_data_quality_dataset
  }
  bigquery_table_bootstrap = {
    stg_orders_id = module.bigquery.staging_orders_table
    stg_returns_id = module.bigquery.staging_returns_table
    stg_inventory_snapshots_id = module.bigquery.staging_inventory_snapshots_table
    stg_product_id = module.bigquery.staging_product_table
  }
  
  bigquery_details = {
    location = var.dataset_location
    bigquery_datasets = local.bigquery_datasets
    bigquery_tables = local.bigquery_tables
  }
  bigquery_bootstrap = {
    location = var.dataset_location
    bigquery_datasets = local.bigquery_dataset_bootstrap
    bigquery_tables = local.bigquery_table_bootstrap
  }
  env_variables = merge(var.env_variables, { ENV = var.environment })
  labels = merge(var.labels, { env = var.environment })
}