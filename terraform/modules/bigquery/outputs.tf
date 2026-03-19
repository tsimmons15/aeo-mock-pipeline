# outputs.tf
output "dataset_id" {
  value = google_bigquery_dataset.warehouse.dataset_id
}

output "runtime_service_account_email" {
  value = google_service_account.runtime.email
}

output "events_table_id" {
  value = google_bigquery_table.events.id
}
