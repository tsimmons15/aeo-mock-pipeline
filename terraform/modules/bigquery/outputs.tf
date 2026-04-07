output "runtime_service_account_email" {
  value = google_service_account.runtime.email
}

#####################################################################
# Dataset outputs
#####################################################################

output "retail_staging_dataset" {
  value = google_bigquery_dataset.retail_staging
}

output "retail_core_dataset" {
  value = google_bigquery_dataset.retail
}

output "retail_mart_merchandising_dataset" {
  value = google_bigquery_dataset.retail_mart_merchandising
}

output "retail_mart_customer_demography_dataset" {
  value = google_bigquery_dataset.retail_mart_customer_demography
}

output "retail_data_quality_dataset" {
  value = google_bigquery_dataset.retail_data_quality
}

#####################################################################
# Table outputs
#####################################################################

output "staging_orders_table" {
  value = google_bigquery_table.stg_orders
}
output "staging_returns_table" {
  value = google_bigquery_table.stg_returns
}
output "staging_inventory_snapshots_table" {
  value = google_bigquery_table.stg_inventory_snapshots
}
output "staging_product_table" {
  value = google_bigquery_table.stg_product
}