resource "google_pubsub_topic_iam_member" "mock_generator_publisher" {
  project = var.project.id
  topic   = var.pubsub_topic_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.mock_generator.email}"
}

resource "google_storage_bucket_iam_member" "mock_generator_storage" {
  bucket = var.raw_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.mock_generator.email}"
}

resource "google_service_account" "mock_generator" {
  project      = var.project.id
  account_id   = var.sa_name
  display_name = var.sa_name
}