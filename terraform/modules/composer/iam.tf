

resource "google_service_account" "composer" {
  provider     = google-beta
  account_id   = var.composer_sa_name
  display_name = "Cloud Composer runtime service account"
}

resource "google_project_iam_member" "composer_worker" {
  provider = google-beta
  project  = var.project.id
  member   = "serviceAccount:${google_service_account.composer.email}"
  role     = "roles/composer.worker"
}

resource "google_project_iam_member" "composer_secret_accessor" {
  provider = google-beta
  project  = var.project.id
  member   = "serviceAccount:${google_service_account.composer.email}"
  role     = "roles/secretmanager.secretAccessor"
}

resource "google_project_iam_member" "composer_env_creator" {
    provider = google-beta
    project = var.project.id
    member = "serviceAccount:${var.bootstrap_sa.email}"
    role = "roles/composer.admin"
}

resource "google_project_iam_member" "secrets_creator" {
    provider = google-beta
    project = var.project.id
    member = "serviceAccount:${var.bootstrap_sa.email}"
    role = "roles/secretmanager.admin"
}