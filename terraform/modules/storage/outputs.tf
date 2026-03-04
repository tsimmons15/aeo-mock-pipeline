output "dataflow_storage" {
  value = google_storage_bucket.dataflow_storage.name
}

output "raw_landing_name" {
  value = google_storage_bucket.raw_landing.name
}