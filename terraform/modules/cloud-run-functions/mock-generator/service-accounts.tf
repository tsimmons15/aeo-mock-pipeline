resource "google_service_account" "mock_generator" {
  project      = var.project_id
  account_id   = var.sa_name
  display_name = var.sa_name
}