resource "null_resource" "api_enablement_ready" {

    depends_on = [
        google_service_account.composer,
        google_project_iam_member.composer_worker,
        google_project_iam_member.composer_secret_accessor,
        google_project_iam_member.composer_env_creator,
        google_project_iam_member.secrets_creator
    ]
}

resource "google_project_service" "composer_api" {
  provider = google-beta
  project  = var.project.id
  service  = "composer.googleapis.com"

  disable_on_destroy                    = false
  check_if_service_has_usage_on_destroy = true

  depends_on = [null_resource.api_enablement_ready]
}

resource "google_composer_environment" "this" {
  provider = google-beta
  project  = var.project.id
  region   = var.region
  name     = var.composer_env_name

  depends_on = [
    google_project_service.composer_api,
    null_resource.api_enablement_ready
  ]

  config {
    software_config {
      image_version             = var.image_version
      pypi_packages             = var.python.packages
      env_variables             = var.env_variables
      airflow_config_overrides  = var.airflow_config_overrides
    }

    node_config {
      service_account = google_service_account.composer.email
    }
  }

  labels = var.labels
}