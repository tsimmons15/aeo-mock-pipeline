variable "project" {
    type = object({
        id         = string
        number     = string
    })
#    default     = ""
    description = "A collection of the project details."
}

variable "region" { 
    type        = string 
    default     = "us-east1"
    description = "The region this module will be deployed to"
}

variable "dataflow_runner_sa_name" {
    type        = string
#    default     = ""
    description = "The name for the service account the dataflow runs under"
}

variable "dataflow_launcher_sa_name" {
    type        = string
#    default     = ""
    description = "The name for the service account that launches the dataflow job"
}

variable "staging_bucket_name" {
    type        = string
#    default     = ""
    description = "The bucket containing other files needed for running the dataflow job"
}

variable "ingestion_bucket_name" {
    type        = string
#    default     = ""
    description = "The raw bucket for the batch dataflow ingestion to pull from"
}

variable "pubsub_details" { 
    type        = object({
        topic_name      = string
        topic_id        = string
        browse_event    = string
        cart_event      = string
        commerce_event  = string
        return_event    = string
        inventory_event = string
    })
#    default     = ""
    description = "The pubsub details including the details this module is supposed to read from"
}

variable "bigquery_datasets" {
    type = object({
        retail_staging     = string
        core_retail        = string
        merchandising_mart = string
        demography_mart    = string
        data_quality       = string
    })
#    default     = ""
    description = "A collection of the bigquery datasets."
}