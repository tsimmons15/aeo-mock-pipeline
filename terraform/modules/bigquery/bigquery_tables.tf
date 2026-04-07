resource "google_bigquery_table" "stg_orders" {
  project    = var.project.id
  dataset_id = google_bigquery_dataset.retail_staging.dataset_id
  table_id   = var.stg_orders_id

  deletion_protection = true

  schema = jsonencode([
    { name = "schema_version",  type = "STRING",    mode = "NULLABLE" },
    { name = "order_id",        type = "STRING",    mode = "REQUIRED" },
    { name = "brand",           type = "STRING",    mode = "NULLABLE" },
    { name = "order_time",      type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "ingest_time",     type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "channel",         type = "STRING",    mode = "NULLABLE" },
    { name = "store_id",        type = "STRING",    mode = "NULLABLE" },
    { name = "ship_method",     type = "STRING",    mode = "NULLABLE" },
    { name = "payment_type",    type = "STRING",    mode = "NULLABLE" },
    { name = "customer",        type = "JSON",      mode = "NULLABLE" },
    { name = "items",           type = "JSON",      mode = "NULLABLE" },
    { name = "totals",          type = "JSON",      mode = "NULLABLE" }
  ])

  time_partitioning {
    type  = "DAY"
    field = "order_time"
  }

  clustering = ["brand", "channel"]

  require_partition_filter = true

  labels = {
    env        = var.environment
    managed_by = "terraform"
  }
}

resource "google_bigquery_table" "stg_returns" {
  project    = var.project.id
  dataset_id = google_bigquery_dataset.retail_staging.dataset_id
  table_id   = var.stg_returns_id

  deletion_protection = true

  schema = jsonencode([
    { name = "schema_version",    type = "STRING",    mode = "NULLABLE" },
    { name = "return_id",         type = "STRING",    mode = "REQUIRED" },
    { name = "original_order_id", type = "STRING",    mode = "NULLABLE" },
    { name = "brand",             type = "STRING",    mode = "NULLABLE" },
    { name = "return_time",       type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "ingest_time",       type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "store_id",          type = "STRING",    mode = "NULLABLE" },
    { name = "sku",               type = "STRING",    mode = "NULLABLE" },
    { name = "qty",               type = "INTEGER",   mode = "NULLABLE" },
    { name = "reason",            type = "STRING",    mode = "NULLABLE" },
    { name = "resolution",        type = "STRING",    mode = "NULLABLE" },
    { name = "refund_amount",     type = "NUMERIC",   mode = "NULLABLE" },
    { name = "currency",          type = "STRING",    mode = "NULLABLE" }
  ])

  time_partitioning {
    type  = "DAY"
    field = "return_time"
  }

  clustering = ["brand", "reason"]

  require_partition_filter = true

  labels = {
    env        = var.environment
    managed_by = "terraform"
  }
}

resource "google_bigquery_table" "stg_inventory_snapshots" {
  project    = var.project.id
  dataset_id = google_bigquery_dataset.retail_staging.dataset_id
  table_id   = var.stg_inventory_snapshots_id

  deletion_protection = true

  schema = jsonencode([
    { name = "schema_version", type = "STRING",    mode = "NULLABLE" },
    { name = "snapshot_time",  type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "ingest_time",    type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "store_id",       type = "STRING",    mode = "REQUIRED" },
    { name = "sku",            type = "STRING",    mode = "REQUIRED" },
    { name = "on_hand",        type = "INTEGER",   mode = "NULLABLE" },
    { name = "on_order",       type = "INTEGER",   mode = "NULLABLE" },
    { name = "reserved",       type = "INTEGER",   mode = "NULLABLE" }
  ])

  time_partitioning {
    type  = "DAY"
    field = "snapshot_time"
  }

  clustering = ["store_id", "sku"]

  require_partition_filter = true

  labels = {
    env        = var.environment
    managed_by = "terraform"
  }
}

resource "google_bigquery_table" "stg_product" {
  project    = var.project.id
  dataset_id = google_bigquery_dataset.retail_staging.dataset_id
  table_id   = var.stg_product_id

  deletion_protection = true

  schema = jsonencode([
    { name = "schema_version", type = "STRING",    mode = "NULLABLE" },
    { name = "sku",            type = "STRING",    mode = "REQUIRED" },
    { name = "brand",          type = "STRING",    mode = "NULLABLE" },
    { name = "dept",           type = "STRING",    mode = "NULLABLE" },
    { name = "category",       type = "STRING",    mode = "NULLABLE" },
    { name = "name",           type = "STRING",    mode = "NULLABLE" },
    { name = "base_price",     type = "NUMERIC",   mode = "NULLABLE" },
    { name = "color",          type = "STRING",    mode = "NULLABLE" },
    { name = "size_curve",     type = "STRING",    mode = "NULLABLE" },
    { name = "effective_time", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "ingest_time",    type = "TIMESTAMP", mode = "REQUIRED" }
  ])

  time_partitioning {
    type  = "DAY"
    field = "effective_time"
  }

  clustering = ["brand", "dept"]

  require_partition_filter = false

  labels = {
    env        = var.environment
    managed_by = "terraform"
  }
}