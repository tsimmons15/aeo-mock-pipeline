output "mock_generator_uri" {
  value = google_cloudfunctions2_function.aeo_mock_generator.service_config[0].uri
}