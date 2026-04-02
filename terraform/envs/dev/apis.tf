resource "google_project_service" "required" {
  for_each = toset([
#    "cloudresourcemanager.googleapis.com",
    "bigquery.googleapis.com",
    "iam.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "eventarc.googleapis.com",
    "composer.googleapis.com",
    "secretmanager.googleapis.com"
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}