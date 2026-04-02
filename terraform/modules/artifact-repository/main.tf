# Defines an repository for python artifacts
resource "google_artifact_registry_repository" "python_repo" {
  project       = var.project.id
  location      = var.region
  repository_id = var.repository_id
  format        = "PYTHON"
  description   = "Private Python packages for AEO Dataflow pipelines."
}

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "cicd_pool" {
  project                   = var.project.id
  workload_identity_pool_id = var.cicd_workload_id
  display_name              = "CICD Pool"
  description               = "WIF pool for CICD OIDC authentication."
  disabled                  = false
}

# OIDC Provider scoped to this specific repo
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project.id
  workload_identity_pool_id          = google_iam_workload_identity_pool.cicd_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"        = "assertion.sub"
    "attribute.repository"  = "assertion.repository"
    "attribute.ref"         = "assertion.ref"
    "attribute.workflow"    = "assertion.workflow"
  }

  # Restrict to only this repo — prevents any other GitHub repo from
  # using this pool even if they somehow know the provider details
  attribute_condition = "attribute.repository == '${var.github_org}/${var.github_repo}'"
}

# Allow the WIF pool identity to impersonate the CI service account
resource "google_service_account_iam_member" "wif_sa_binding" {
  service_account_id = var.cicd_runner.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.cicd_pool.workload_identity_pool_id}/attribute.repository/${var.github_org}/${var.github_repo}"
}