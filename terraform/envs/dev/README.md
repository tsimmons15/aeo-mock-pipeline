Variables
Set these variables before running the following commands:

```bash
export PROJECT_ID="your-project-id"
export PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"

export TF_SA_NAME="terraform-bootstrap"
export TF_SA_EMAIL="${TF_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Must be globally unique.
export TF_STATE_BUCKET="${PROJECT_ID}-tf-state"

# Choose your region or multi-region.
export BUCKET_LOCATION="us-east1"

# Principal allowed to impersonate terraform-bootstrap.
# Examples:
#   user:you@example.com
#   serviceAccount:ci-runner@another-project.iam.gserviceaccount.com
export TF_RUNNER_PRINCIPAL="user:you@example.com"

gcloud config set project "$PROJECT_ID"
```

1) Create the service account
```bash
gcloud iam service-accounts create "$TF_SA_NAME" \
  --project="$PROJECT_ID" \
  --display-name="Terraform Bootstrap"
```

Google documents service account creation as a standard IAM workflow.
​

2) Grant project roles to terraform-bootstrap
The exact least-privilege permissions depend on what your Terraform code manages, so the role set below is a practical bootstrap baseline rather than a universal minimum.

```bash
ROLE_LIST=(
  "roles/storage.admin"
  "roles/serviceusage.serviceUsageAdmin"
  "roles/resourcemanager.projectIamAdmin"
  "roles/iam.serviceAccountAdmin"
  "roles/iam.serviceAccountUser"
)

for ROLE in "${ROLE_LIST[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${TF_SA_EMAIL}" \
    --role="$ROLE"
done
```

Why these roles
- roles/storage.admin: 
    - create and manage the Terraform state bucket.
- roles/serviceusage.serviceUsageAdmin: 
    - enable required Google APIs for Terraform-managed services.
- roles/resourcemanager.projectIamAdmin: 
    - manage project IAM bindings.
- roles/iam.serviceAccountAdmin: 
    - create and manage service accounts.
- roles/iam.serviceAccountUser: 
    - attach service accounts to resources when required.

3) Grant impersonation access
Google documents service account impersonation as a Terraform authentication pattern, which avoids distributing long-lived service account keys.
​

```bash
gcloud iam service-accounts add-iam-policy-binding "$TF_SA_EMAIL" \
  --member="$TF_RUNNER_PRINCIPAL" \
  --role="roles/iam.serviceAccountTokenCreator"
```

If the runner also needs to attach terraform-bootstrap to resources, grant roles/iam.serviceAccountUser on the service account too.

```bash
gcloud iam service-accounts add-iam-policy-binding "$TF_SA_EMAIL" \
  --member="$TF_RUNNER_PRINCIPAL" \
  --role="roles/iam.serviceAccountUser"
```

4) Create the Terraform state bucket

Google’s documented HNS bucket creation flow uses gcloud storage buckets create with --uniform-bucket-level-access and --enable-hierarchical-namespace, and supports --default-storage-class, --location, and --project.
​

```bash
gcloud storage buckets create "gs://${TF_STATE_BUCKET}" \
  --project="$PROJECT_ID" \
  --location="$BUCKET_LOCATION" \
  --default-storage-class="COLDLINE" \
  --uniform-bucket-level-access \
  --enable-hierarchical-namespace
```

5) Disable soft delete
Google documents disabling bucket soft delete with gcloud storage buckets update --clear-soft-delete.
​

```bash
gcloud storage buckets update --clear-soft-delete "gs://${TF_STATE_BUCKET}"
```

Google also notes that the change is not always instantaneous across Cloud Storage metadata, so waiting briefly before follow-up operations is recommended.
​
```bash
sleep 30
```

6) Verify the bucket
```bash
gcloud storage buckets describe "gs://${TF_STATE_BUCKET}"
```

Confirm the bucket shows these properties:

Storage class is COLDLINE.
​

Uniform bucket-level access is enabled.
​

Hierarchical namespace is enabled.
​

Soft delete is cleared or effectively disabled. Google’s documented API example for disabling soft delete sets the retention duration to 0.
​

7) Optional local auth for Terraform
If you run Terraform locally with Application Default Credentials, Google documents setting the ADC quota project with `gcloud auth application-default set-quota-project`.
​

```bash
gcloud auth login
gcloud auth application-default login
gcloud auth application-default set-quota-project "$PROJECT_ID"
```

8) Terraform backend block
Use this backend block in your Terraform configuration:

```text
terraform {
  backend "gcs" {
    bucket = "REPLACE_WITH_TF_STATE_BUCKET"
    prefix = "state"
  }
}
```

Example:

```text
terraform {
  backend "gcs" {
    bucket = "your-project-id-tf-state"
    prefix = "state"
  }
}
```

9) One-shot bootstrap script
```bash
export PROJECT_ID="your-project-id"
export PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"

export TF_SA_NAME="terraform-bootstrap"
export TF_SA_EMAIL="${TF_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
export TF_STATE_BUCKET="${PROJECT_ID}-tf-state"
export BUCKET_LOCATION="us-east1"
export TF_RUNNER_PRINCIPAL="user:you@example.com"

gcloud config set project "$PROJECT_ID"

gcloud iam service-accounts create "$TF_SA_NAME" \
  --project="$PROJECT_ID" \
  --display-name="Terraform Bootstrap"

for ROLE in \
  "roles/storage.admin" \
  "roles/serviceusage.serviceUsageAdmin" \
  "roles/resourcemanager.projectIamAdmin" \
  "roles/iam.serviceAccountAdmin" \
  "roles/iam.serviceAccountUser"
do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${TF_SA_EMAIL}" \
    --role="$ROLE"
done

gcloud iam service-accounts add-iam-policy-binding "$TF_SA_EMAIL" \
  --member="$TF_RUNNER_PRINCIPAL" \
  --role="roles/iam.serviceAccountTokenCreator"

gcloud iam service-accounts add-iam-policy-binding "$TF_SA_EMAIL" \
  --member="$TF_RUNNER_PRINCIPAL" \
  --role="roles/iam.serviceAccountUser"

gcloud storage buckets create "gs://${TF_STATE_BUCKET}" \
  --project="$PROJECT_ID" \
  --location="$BUCKET_LOCATION" \
  --default-storage-class="COLDLINE" \
  --uniform-bucket-level-access \
  --enable-hierarchical-namespace

gcloud storage buckets update --clear-soft-delete "gs://${TF_STATE_BUCKET}"

sleep 30

gcloud storage buckets describe "gs://${TF_STATE_BUCKET}"
```