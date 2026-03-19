resource "google_project_iam_member" "runtime_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

# Optional, common for readers using Storage Read API / some connectors.
resource "google_project_iam_member" "runtime_read_session_user" {
  project = var.project_id
  role    = "roles/bigquery.readSessionUser"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

# Dataset-level: runtime SA can mutate data in this dataset only.
resource "google_bigquery_dataset_iam_member" "runtime_data_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.warehouse.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.runtime.email}"
}

# Dataset-level: analysts can read data in this dataset only.
#resource "google_bigquery_dataset_iam_member" "analyst_data_viewer" {
#  project    = var.project_id
#  dataset_id = google_bigquery_dataset.warehouse.dataset_id
#  role       = "roles/bigquery.dataViewer"
#  member     = var.human_analyst_group
#}

# Let a deployer attach/impersonate the runtime SA if needed.
#resource "google_service_account_iam_member" "deployer_sa_user" {
#  service_account_id = google_service_account.runtime.name
#  role               = "roles/iam.serviceAccountUser"
#  member             = var.deployer_member
#}

#resource "google_service_account_iam_member" "deployer_sa_token_creator" {
#  service_account_id = google_service_account.runtime.name
#  role               = "roles/iam.serviceAccountTokenCreator"
#  member             = var.deployer_member
#}
