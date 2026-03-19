# Allows terraform-bootstrap to do look-ups
resource "google_project_iam_member" "terraform_bootstrap_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:terraform-bootstrap@aeo-demo-dev.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "terraform_cloud_build_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:terraform-bootstrap@aeo-demo-dev.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "terraform_artifact_registry_editor" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:terraform-bootstrap@aeo-demo-dev.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "terraform_build_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:terraform-bootstrap@aeo-demo-dev.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "terraform_bigquery_creator" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:terraform-bootstrap@aeo-demo-dev.iam.gserviceaccount.com"
}
