# Storage Buckets Module

This module creates the Google Cloud Storage buckets. Currently, a raw landing bucket and a Dataflow staging/working bucket, both configured with hierarchical namespaces and optional soft delete.

## Resources

- `google_storage_bucket.raw_landing`  
  - Raw landing bucket for initial data ingestion.
  - Uses `uniform_bucket_level_access = true`.
  - Enables hierarchical namespace.
  - Configurable soft delete via `soft_delete_policy.retention_duration_seconds`.

- `google_storage_bucket.dataflow_storage`  
  - Bucket for Dataflow staging and temporary data.
  - Uses `uniform_bucket_level_access = true`.
  - Enables hierarchical namespace.
  - Configurable soft delete via `soft_delete_policy.retention_duration_seconds`.

## Inputs

| Name              | Type   | Default    | Description                                                         | Required |
|-------------------|--------|-----------|---------------------------------------------------------------------|----------|
| `project_id`      | string | n/a       | The project ID to create the storage resources in.                  | yes      |
| `region`          | string | `us-east1`| The region for the buckets.                                         | no       |
| `storage_class`   | string | `COLDLINE`| Storage class (e.g. STANDARD, NEARLINE, COLDLINE, ARCHIVE).         | no       |
| `retention_period`| int    | `0`       | Soft delete retention period in seconds; `0` disables soft delete.  | no       |
| `raw_landing_name`| string | n/a       | The bucket name for the raw landing zone.                           | yes      |
| `dataflow_storage`| string | n/a       | The bucket name for the Dataflow storage bucket.                    | yes      |

## Outputs

| Name               | Description                                        |
|--------------------|----------------------------------------------------|
| `raw_landing_name` | The name of the raw landing bucket.               |
| `dataflow_storage` | The name of the Dataflow storage bucket.          |