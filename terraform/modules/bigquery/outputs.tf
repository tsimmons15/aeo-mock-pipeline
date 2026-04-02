# outputs.tf
output "raw_dataset_id" {
  value = google_bigquery_dataset.raw_warehouse.dataset_id
}

output "core_dataset_id" {
  value = google_bigquery_dataset.core_warehouse.dataset_id
}

output "analytics_dataset_id" {
  value = google_bigquery_dataset.analytics_warehouse.dataset_id
}

output "runtime_service_account_email" {
  value = google_service_account.runtime.email
}

output "events_table_id" {
  value = google_bigquery_table.events.id
}
