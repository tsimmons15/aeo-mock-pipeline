resource "google_secret_manager_secret" "airflow_conn_my_api" {
  provider  = google-beta
  project   = var.project.id
  secret_id = "airflow-connections-my_api"

  replication {
    auto {}
  }
}
