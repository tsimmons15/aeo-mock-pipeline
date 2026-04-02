# Grant the cicd SA write access to the Python Artifact Registry repo
resource "google_artifact_registry_repository_iam_member" "cicd_publisher_writer" {
  project    = var.project.id
  location   = var.region
  repository = google_artifact_registry_repository.python_repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.cicd_runner.email}"
}