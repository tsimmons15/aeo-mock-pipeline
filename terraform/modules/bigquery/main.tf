resource "google_project_service" "services" {
  for_each = toset([
    "bigquery.googleapis.com",
    "iam.googleapis.com"
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = var.runtime_sa_name
  display_name = "BigQuery runtime service account"
  description  = "Used by ETL/ELT workloads that read and write BigQuery"
}

resource "google_bigquery_dataset" "warehouse" {
  project                    = var.project_id
  dataset_id                 = var.dataset_id
  location                   = var.dataset_location
  friendly_name              = "Analytics warehouse"
  description                = "Core analytics dataset"
  delete_contents_on_destroy = false

  labels = {
    env         = var.environment
    managed_by  = "terraform"
    data_domain = "analytics"
  }

  default_table_expiration_ms = null

  depends_on = [google_project_service.services]
}

resource "google_bigquery_table" "events" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.warehouse.dataset_id
  table_id   = "fact_events"

  deletion_protection = true

  schema = jsonencode([
    { name = "event_id",    type = "STRING",    mode = "REQUIRED" },
    { name = "event_ts",    type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "user_id",     type = "STRING",    mode = "NULLABLE" },
    { name = "event_type",  type = "STRING",    mode = "NULLABLE" },
    { name = "source",      type = "STRING",    mode = "NULLABLE" },
    { name = "payload",     type = "JSON",      mode = "NULLABLE" }
  ])

  time_partitioning {
    type  = "DAY"
    field = "event_ts"
  }

  clustering = ["event_type", "source"]

  require_partition_filter = true

  labels = {
    env        = var.environment
    managed_by = "terraform"
  }
}