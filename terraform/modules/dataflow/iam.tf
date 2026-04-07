#####################################################################
# Dataflow Service accounts
#####################################################################
data "google_compute_default_service_account" "default" {
  project = var.project.id
}

resource "google_service_account" "dataflow_runner" {
  project      = var.project.id
  account_id   = var.dataflow_runner_sa_name
  display_name = var.dataflow_runner_sa_name
}

resource "google_service_account" "dataflow_launcher" {
  project      = var.project.id
  account_id   = var.dataflow_launcher_sa_name
  display_name = var.dataflow_launcher_sa_name
}

#####################################################################
# Launcher IAM, impersonation
#####################################################################
resource "google_project_iam_member" "launcher_dataflow_developer" {
  project = var.project.id
  role    = "roles/dataflow.developer"
  member  = "serviceAccount:${google_service_account.dataflow_launcher.email}"
}

resource "google_service_account_iam_member" "launcher_act_as_runner" {
  service_account_id = google_service_account.dataflow_runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.dataflow_launcher.email}"
}

# Workaround: launcher must also be able to act as default compute SA
# until custom SA passthrough is resolved for flex templates.
resource "google_service_account_iam_member" "launcher_act_as_default_runner" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.dataflow_launcher.email}"
}

# Launcher needs access to cloud storage to read template file
resource "google_storage_bucket_iam_member" "staging_storage" {
  bucket = var.staging_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dataflow_launcher.email}"
}

# Conservative choice: give launcher dataset access too, because Dataflow docs
# say both the launching account and the worker SA must have access to datasets
# used by the job.
#resource "google_bigquery_dataset_iam_member" "launcher_bq_data_editor" {
#  project    = var.project.id
#  dataset_id = var.bigquery_dataset_id
#  role       = "roles/bigquery.dataEditor"
#  member     = "serviceAccount:${google_service_account.dataflow_launcher.email}"
#}

#####################################################################
# Runner IAM
#####################################################################
# Runner can execute Dataflow work units.
resource "google_project_iam_member" "runner_dataflow_worker" {
  project = var.project.id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_runner.email}"
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

resource "google_pubsub_topic_iam_member" "runner_pubsub_viewer_topic" {
  project = var.project.id
  topic   = var.pubsub_details.topic_name
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "runner_pubsub_browse_event_subscriber" {
  project      = var.project.id
  subscription = var.pubsub_details.browse_event
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# In case we want the runner to be able to inspect PubSub configs
resource "google_pubsub_subscription_iam_member" "runner_pubsub_browse_event_viewer" {
  project      = var.project.id
  subscription = var.pubsub_details.browse_event
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "runner_pubsub_cart_event_subscriber" {
  project      = var.project.id
  subscription = var.pubsub_details.cart_event
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# In case we want the runner to be able to inspect PubSub configs
resource "google_pubsub_subscription_iam_member" "runner_pubsub_cart_event_viewer" {
  project      = var.project.id
  subscription = var.pubsub_details.cart_event
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "runner_pubsub_commerce_event_subscriber" {
  project      = var.project.id
  subscription = var.pubsub_details.commerce_event
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# In case we want the runner to be able to inspect PubSub configs
resource "google_pubsub_subscription_iam_member" "runner_pubsub_commerce_event_viewer" {
  project      = var.project.id
  subscription = var.pubsub_details.commerce_event
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "runner_pubsub_return_event_subscriber" {
  project      = var.project.id
  subscription = var.pubsub_details.return_event
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# In case we want the runner to be able to inspect PubSub configs
resource "google_pubsub_subscription_iam_member" "runner_pubsub_return_event_viewer" {
  project      = var.project.id
  subscription = var.pubsub_details.return_event
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "runner_pubsub_inventory_event_subscriber" {
  project      = var.project.id
  subscription = var.pubsub_details.inventory_event
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# In case we want the runner to be able to inspect PubSub configs
resource "google_pubsub_subscription_iam_member" "runner_pubsub_inventory_event_viewer" {
  project      = var.project.id
  subscription = var.pubsub_details.inventory_event
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# So the runner can write to the staging tables
resource "google_bigquery_dataset_iam_member" "runner_staging_editor" {
  project    = var.project.id
  dataset_id = var.bigquery_datasets.retail_staging
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# So the runner can write to the pipeline health table
resource "google_bigquery_dataset_iam_member" "runner_data_quality_editor" {
  project    = var.project.id
  dataset_id = var.bigquery_datasets.data_quality
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

#####################################################################
# Default Runner IAM
#####################################################################
# Runner can execute Dataflow work units.
resource "google_project_iam_member" "default_runner_dataflow_worker" {
  project = var.project.id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Staging/temp bucket access: read + write.
resource "google_storage_bucket_iam_member" "default_runner_staging_admin" {
  bucket = var.staging_bucket_name
  role   = "roles/storage.admin"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Input GCS bucket access: read only.
resource "google_storage_bucket_iam_member" "default_runner_input_viewer" {
  bucket = var.ingestion_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_pubsub_topic_iam_member" "default_runner_pubsub_viewer_topic" {
  project = var.project.id
  topic   = var.pubsub_details.topic_name
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_browse_event_subscriber" {
  project      = var.project.id
  subscription = var.pubsub_details.browse_event
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# In case we want the runner to be able to inspect PubSub configs
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_browse_event_viewer" {
  project      = var.project.id
  subscription = var.pubsub_details.browse_event
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_cart_event_subscriber" {
  project      = var.project.id
  subscription = var.pubsub_details.cart_event
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# In case we want the runner to be able to inspect PubSub configs
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_cart_event_viewer" {
  project      = var.project.id
  subscription = var.pubsub_details.cart_event
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_commerce_event_subscriber" {
  project      = var.project.id
  subscription = var.pubsub_details.commerce_event
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# In case we want the runner to be able to inspect PubSub configs
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_commerce_event_viewer" {
  project      = var.project.id
  subscription = var.pubsub_details.commerce_event
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_return_event_subscriber" {
  project      = var.project.id
  subscription = var.pubsub_details.return_event
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# In case we want the runner to be able to inspect PubSub configs
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_return_event_viewer" {
  project      = var.project.id
  subscription = var.pubsub_details.return_event
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Pub/Sub consume permissions on the subscription.
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_inventory_event_subscriber" {
  project      = var.project.id
  subscription = var.pubsub_details.inventory_event
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# In case we want the runner to be able to inspect PubSub configs
resource "google_pubsub_subscription_iam_member" "default_runner_pubsub_inventory_event_viewer" {
  project      = var.project.id
  subscription = var.pubsub_details.inventory_event
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# So the runner can write to the staging tables
resource "google_bigquery_dataset_iam_member" "default_runner_staging_editor" {
  project    = var.project.id
  dataset_id = var.bigquery_datasets.retail_staging
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# So the runner can write to the pipeline health table
resource "google_bigquery_dataset_iam_member" "default_runner_data_quality_editor" {
  project    = var.project.id
  dataset_id = var.bigquery_datasets.data_quality
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}