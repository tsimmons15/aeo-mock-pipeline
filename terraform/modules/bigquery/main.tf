resource "google_project_service" "services" {
  for_each = toset([
    "bigquery.googleapis.com",
    "iam.googleapis.com"
  ])

  project            = var.project.id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "runtime" {
  project      = var.project.id
  account_id   = var.runtime_sa_name
  display_name = "BigQuery runtime service account"
  description  = "Used by ETL/ELT workloads that read and write BigQuery"
}

resource "google_bigquery_dataset" "retail_staging" {
  project                    = var.project.id
  dataset_id                 = var.bigquery_details.datasets.staging_dataset
  location                   = var.bigquery_details.dataets.location
  friendly_name              = "Landing warehouse"
  description                = "Landing zone/staging dataset"
  delete_contents_on_destroy = false

  labels = {
    env         = var.environment
    managed_by  = "terraform"
    data_domain = "lz"
  }

  default_table_expiration_ms = null

  depends_on = [google_project_service.services]
}

resource "google_bigquery_dataset" "retail" {
  project                    = var.project.id
  dataset_id                 = var.bigquery_details.datasets.core_dataset
  location                   = var.bigquery_details.dataets.location
  friendly_name              = "Core warehouse"
  description                = "Core dataset for this retail data"
  delete_contents_on_destroy = false

  labels = {
    env         = var.environment
    managed_by  = "terraform"
    data_domain = "retail"
  }

  default_table_expiration_ms = null

  depends_on = [google_project_service.services]
}

resource "google_bigquery_dataset" "retail_mart_merchandising" {
  project                    = var.project.id
  dataset_id                 = var.bigquery_details.datasets.merchandising_dataset
  location                   = var.bigquery_details.dataets.location
  friendly_name              = "Merchandising analytics warehouse"
  description                = "Product/inventory analytics"
  delete_contents_on_destroy = false

  labels = {
    env         = var.environment
    managed_by  = "terraform"
    data_domain = "inventory"
  }

  default_table_expiration_ms = null

  depends_on = [google_project_service.services]
}

resource "google_bigquery_dataset" "retail_mart_customer_demography" {
  project                    = var.project.id
  dataset_id                 = var.bigquery_details.datasets.demography_dataset
  location                   = var.bigquery_details.dataets.location
  friendly_name              = "Analytics warehouse"
  description                = "Customer behavior, return rates, loyalty"
  delete_contents_on_destroy = false

  labels = {
    env         = var.environment
    managed_by  = "terraform"
    data_domain = "customer"
  }

  default_table_expiration_ms = null

  depends_on = [google_project_service.services]
}

resource "google_bigquery_dataset" "retail_data_quality" {
  project                    = var.project.id
  dataset_id                 = var.bigquery_details.datasets.data_quality_dataset
  location                   = var.bigquery_details.dataets.location
  friendly_name              = "DQ results warehouse"
  description                = "Pipeline health and calculated SLA data"
  delete_contents_on_destroy = false

  labels = {
    env         = var.environment
    managed_by  = "terraform"
    data_domain = "customer"
  }

  default_table_expiration_ms = null

  depends_on = [google_project_service.services]
}