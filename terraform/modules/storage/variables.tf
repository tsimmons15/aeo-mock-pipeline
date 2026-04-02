variable "project" {
    type = object({
        id         = string
        number     = string
    })
#    default     = ""
    description = "A collection of the project details."
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

variable "dataflow_staging" {
    type = string
#    default = ""
    description = "The bucket name associated with the dataflow staging/templates."
}

variable "raw_landing_name" {
    type = string
#    default = ""
    description = "The bucket name associated with the raw landing zone."
}