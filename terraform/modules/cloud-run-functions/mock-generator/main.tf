locals {
  function_source_dir = (
    var.function_source_dir != ""
    ? var.function_source_dir
    : "${path.module}/../../../../app/mock-generator"
  )
  function_files = sort(fileset(local.function_source_dir, "**"))
  function_hash  = sha256(join("", [
    for f in local.function_files :
    filesha256("${local.function_source_dir}/${f}")
  ]))
}

resource "google_storage_bucket" "function_source_bucket" {
  project                     = var.project.id
  name                        = "${var.project.id}-mock-generator-src"
  location                    = var.region
  uniform_bucket_level_access = true
}

data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = local.function_source_dir
  output_path = "${path.module}/.tmp/mock-generator.zip"
}

resource "google_storage_bucket_object" "function_zip" {
  bucket = google_storage_bucket.function_source_bucket.name
  name   = "mock-generator-${substr(local.function_hash, 0, 16)}.zip"
  source = data.archive_file.function_zip.output_path
}

resource "google_cloudfunctions2_function" "aeo_mock_generator" {
  provider    = google-beta
  project     = var.project.id
  location    = var.region
  name        = var.generator_name
  description = "AEO mock generator (stream Pub/Sub, batch GCS)"

  build_config {
    runtime     = "python311"
    entry_point = "aeo_mock"
    service_account = var.bootstrap_sa.name

    source {
      storage_source {
        bucket = google_storage_bucket.function_source_bucket.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    available_memory      = "512M"
    timeout_seconds       = 540
    service_account_email = google_service_account.mock_generator.email

    environment_variables = {
      AEO_PROJECT_ID      = var.project.id
      AEO_PUBSUB_TOPIC_ID = var.pubsub_topic_id
      AEO_RAW_GCS_BUCKET  = var.raw_bucket_name
      AEO_RAW_GCS_PREFIX  = "raw/aeo"
      AEO_BATCH_GZIP      = "true"
    }
  }

  depends_on = [
    google_pubsub_topic_iam_member.mock_generator_publisher,
    google_storage_bucket_iam_member.mock_generator_storage,
  ]
}