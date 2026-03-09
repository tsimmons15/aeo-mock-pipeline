variable "project_id" {
    type = string
#    default = ""
    description = "The project id to create the storage items in"
}

variable "region" {
    type = string
    default = "us-east1"
    description = "The region tied to this storage instance."
}

variable "storage_class" {
    type = string
    default = "COLDLINE"
    description = "The storage class attached to the storage. Standard is routine access, Archive is for archival purposes."
}

variable "retention_period" {
    type = number
    default = 0
    description = "Soft delete retention period in seconds. 0 disables."
}

variable "dataflow_storage" {
    type = string
#    default = ""
    description = "The bucket name associated with the dataflow processing."
}

variable "raw_landing_name" {
    type = string
#    default = ""
    description = "The bucket name associated with the raw landing zone."
}