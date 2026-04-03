resource "google_service_account" "dataflow_runner" {
<<<<<<< HEAD
  project      = var.project_id
=======
  project      = var.project.id
>>>>>>> release/terraform
  account_id   = var.dataflow_runner_sa_name
  display_name = var.dataflow_runner_sa_name
}

resource "google_service_account" "dataflow_launcher" {
<<<<<<< HEAD
  project      = var.project_id
=======
  project      = var.project.id
>>>>>>> release/terraform
  account_id   = var.dataflow_launcher_sa_name
  display_name = var.dataflow_launcher_sa_name
}

# Launcher can submit Dataflow jobs.
resource "google_project_iam_member" "launcher_dataflow_developer" {
<<<<<<< HEAD
  project = var.project_id
=======
  project = var.project.id
>>>>>>> release/terraform
  role    = "roles/dataflow.developer"
  member  = "serviceAccount:${google_service_account.dataflow_launcher.email}"
}

# Launcher can act as the runner service account.
resource "google_service_account_iam_member" "launcher_act_as_runner" {
  service_account_id = google_service_account.dataflow_runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.dataflow_launcher.email}"
}

# Launcher needs access to cloud storage to read template file
resource "google_storage_bucket_iam_member" "mock_generator_storage" {
  bucket = var.staging_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dataflow_launcher.email}"
}

# Runner can execute Dataflow work units.
resource "google_project_iam_member" "runner_dataflow_worker" {
<<<<<<< HEAD
  project = var.project_id
=======
  project = var.project.id
>>>>>>> release/terraform
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# Staging/temp bucket access: read + write.
resource "google_storage_bucket_iam_member" "runner_staging_object_admin" {
  bucket = var.staging_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# Staging/temp bucket access: read + write.
resource "google_storage_bucket_iam_member" "runner_staging_admin" {
  bucket = var.staging_bucket_name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# Input GCS bucket access: read only.
resource "google_storage_bucket_iam_member" "runner_input_viewer" {
  bucket = var.ingestion_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "runner_pubsub_subscriber" {
<<<<<<< HEAD
  project      = var.project_id
=======
  project      = var.project.id
>>>>>>> release/terraform
  subscription = var.pubsub_subscription_name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# Recommended so Dataflow can inspect Pub/Sub config.
resource "google_pubsub_subscription_iam_member" "runner_pubsub_viewer_sub" {
<<<<<<< HEAD
  project      = var.project_id
=======
  project      = var.project.id
>>>>>>> release/terraform
  subscription = var.pubsub_subscription_name
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

resource "google_pubsub_topic_iam_member" "runner_pubsub_viewer_topic" {
<<<<<<< HEAD
  project = var.project_id
=======
  project = var.project.id
>>>>>>> release/terraform
  topic   = var.pubsub_topic_name
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# BigQuery write access on the destination dataset.
#resource "google_bigquery_dataset_iam_member" "runner_bq_data_editor" {
<<<<<<< HEAD
#  project    = var.project_id
=======
#  project    = var.project.id
>>>>>>> release/terraform
#  dataset_id = var.bigquery_dataset_id
#  role       = "roles/bigquery.dataEditor"
#  member     = "serviceAccount:${google_service_account.dataflow_runner.email}"
#}

# Conservative choice: give launcher dataset access too, because Dataflow docs
# say both the launching account and the worker SA must have access to datasets
# used by the job.
#resource "google_bigquery_dataset_iam_member" "launcher_bq_data_editor" {
<<<<<<< HEAD
#  project    = var.project_id
=======
#  project    = var.project.id
>>>>>>> release/terraform
#  dataset_id = var.bigquery_dataset_id
#  role       = "roles/bigquery.dataEditor"
#  member     = "serviceAccount:${google_service_account.dataflow_launcher.email}"
#}

#######################################################################################
# Apparently, custom templates do not run under custom service accounts, or I'm
# not seeing how to switch it from executing with the default SA. Temporary work-around
#######################################################################################

data "google_compute_default_service_account" "default" {
<<<<<<< HEAD
  project = var.project_id
=======
  project = var.project.id
>>>>>>> release/terraform
}

# Launcher can act as the runner service account.
resource "google_service_account_iam_member" "launcher_act_as_default_runner" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.dataflow_launcher.email}"
}

# Runner can execute Dataflow work units.
resource "google_project_iam_member" "default_runner_dataflow_worker" {
<<<<<<< HEAD
  project = var.project_id
=======
  project = var.project.id
>>>>>>> release/terraform
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Staging/temp bucket access: read + write.
resource "google_storage_bucket_iam_member" "default_runner_staging_admin" {
  bucket = var.staging_bucket_name
  role   = "roles/storage.admin"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Staging/temp bucket access: read + write.
resource "google_storage_bucket_iam_member" "default_runner_staging_object_admin" {
  bucket = var.staging_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Input GCS bucket access: read only.
resource "google_storage_bucket_iam_member" "default_runner_input_viewer" {
  bucket = var.ingestion_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:162445529275-compute@developer.gserviceaccount.com"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_subscriber" {
  project      = var.project.id
  subscription = var.pubsub_subscription_name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:162445529275-compute@developer.gserviceaccount.com"
}

# Recommended so Dataflow can inspect Pub/Sub config.
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_viewer_sub" {
  project      = var.project.id
  subscription = var.pubsub_subscription_name
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:162445529275-compute@developer.gserviceaccount.com"
}

resource "google_pubsub_topic_iam_member" "default_runner_pubsub_viewer_topic" {
  project = var.project.id
  topic   = var.pubsub_topic_name
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:162445529275-compute@developer.gserviceaccount.com"
}

# BigQuery write access on the destination dataset.
#resource "google_bigquery_dataset_iam_member" "default_runner_bq_data_editor" {
#  project    = var.project.id
#  dataset_id = var.bigquery_dataset_id
#  role       = "roles/bigquery.dataEditor"
#  member     = "serviceAccount:162445529275-compute@developer.gserviceaccount.com"
#}