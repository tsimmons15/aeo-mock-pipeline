# Retrieves the bootstrap account so it's not hard-coded.
data "google_service_account" "bootstrap" {
  project    = var.project_id
  account_id = var.bootstrap_sa_name
}

#Allows terraform-bootstrap to edit workload identity pools
resource "google_project_iam_member" "terraform_bootstrap_workload_admin" {
  project = var.project_id
  role = "roles/iam.workloadIdentityPoolAdmin"
  member = "serviceAccount:${data.google_service_account.bootstrap.email}"
}

resource "google_project_iam_member" "terraform_bootstrap_artifact_registry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${data.google_service_account.bootstrap.email}"
}

# Allows terraform-bootstrap to do look-ups
resource "google_project_iam_member" "terraform_bootstrap_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${data.google_service_account.bootstrap.email}"
}

resource "google_project_iam_member" "terraform_cloud_build_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${data.google_service_account.bootstrap.email}"
}

resource "google_project_iam_member" "terraform_build_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_service_account.bootstrap.email}"
}

resource "google_project_iam_member" "terraform_bigquery_creator" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${data.google_service_account.bootstrap.email}"
}

# The CICD-controlling service account
resource "google_service_account" "cicd_runner" {
  project      = var.project_id
  account_id   = var.cicd_sa_name
  display_name = var.cicd_sa_name
}
