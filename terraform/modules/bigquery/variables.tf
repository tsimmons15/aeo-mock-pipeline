variable "project" {
    type = object({
        id         = string
        number     = string
    })
#    default     = ""
    description = "A collection of the project details."
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "environment" {
  type    = string
  default = "dev"
}

#####################################################################
# IAM group definitions
#####################################################################
#variable "human_analyst_group" {
#  type        = string
#  description = "Example: group:analytics@example.com"
#}

variable "runtime_sa_name" {
  type    = string
  default = "bq-runtime"
}

#variable "deployer_member" {
#  type        = string
#  description = "Example: user:you@example.com or serviceAccount:terraform@project.iam.gserviceaccount.com"
#}



#####################################################################
# BigQuery variables
#####################################################################
variable "bigquery_details" {
  type = object({
    location                     = string
    bigquery_dataset_bootstrap = object({
      retail_staging             = string
      core_retail                = string
      merchandising_mart         = string
      demography_mart            = string
      data_quality               = string
    })
    bigquery_table_bootstrap = object({
      stg_orders_id              = string
      stg_returns_id             = string
      stg_inventory_snapshots_id = string
      stg_product_id             = string
    })
  })
}