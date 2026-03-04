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
echo "wip"
```