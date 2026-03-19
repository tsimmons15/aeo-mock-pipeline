output "dataflow_staging" {
  value = google_storage_bucket.dataflow_staging.name
}

output "raw_landing_name" {
  value = google_storage_bucket.raw_landing.name
}