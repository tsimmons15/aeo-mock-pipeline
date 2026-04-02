resource "google_storage_bucket" "raw_landing" {
  name     = var.raw_landing_name
  project  = var.project.id
  location = var.region

  storage_class = var.storage_class
  uniform_bucket_level_access = true

  hierarchical_namespace {
    enabled = true
  }

  soft_delete_policy {
    retention_duration_seconds = var.retention_period  # 0 = soft delete disabled
  }
}

resource "google_storage_bucket" "dataflow_staging" {
  name     = var.dataflow_staging
  project  = var.project.id
  location = var.region

  storage_class = var.storage_class
  uniform_bucket_level_access = true

  hierarchical_namespace {
    enabled = true
  }

  soft_delete_policy {
    retention_duration_seconds = var.retention_period
  }
}