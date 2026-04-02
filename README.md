# AEO Mock Data Pipeline
This is a mock pipeline, meant to theoretically mirror a GCP data pipeline used by the retail company, American Eagle Outfitters.

## Architecture
POS/CRM Files → GCS → Dataflow (Beam Python) → BigQuery (partitioned/clustered)
Web Events → Pub/Sub → Dataflow (Beam Python streaming) → BigQuery
Cloud Composer → Orchestrates batch jobs + monitors streaming

## Project structure
-- aeo-data-platform
    -- app
        -- mock-generator
    -- terraform
        -- envs
            -- dev
            -- prod
        -- modules
            -- cloud-run-functions
                -- mock-generator

## Quick Start
```bash
# Create the identity
# Create the Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --project="aeo-demo-dev" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create the OIDC provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="aeo-demo-dev" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="attribute.repository=='your-org/your-repo'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Allow the pool to impersonate the CI service account
gcloud iam service-accounts add-iam-policy-binding \
  "ci-publisher@aeo-demo-dev.iam.gserviceaccount.com" \
  --project="aeo-demo-dev" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/your-org/your-repo"
```