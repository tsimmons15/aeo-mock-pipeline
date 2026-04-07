#####################################################################
# Mock Generator Inputs
#####################################################################

variable "project" {
    type = object({
        id         = string
        number     = string
    })
#    default     = ""
    description = "A collection of the project details."
}

variable "region"          { 
    type        = string 
    default     = "us-east1"
    description = "The region this module will be deployed to"
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
    description = "The pubsub details including the details this module is supposed to publish to"
}

variable "raw_bucket_name" { 
    type        = string
#    default     = ""
    description = "The raw landing pad that mock data will be generated in."
}

variable "generator_name" {
    type = string
    default = "aeo-mock-generator"
    description = "The data mock generator name in Cloud Run."
}

variable "sa_name" {
    type        = string
    default     = "mock-generator"
    description = "The service account that the Cloud Run function runs as."
}

variable "function_source_dir" {
    type        = string
    description = "Optional override for the mock-generator source directory."
    default     = ""
}

variable "function_name" {
    type        = string
#    default     = ""
    description = "The name the generated cloud run function should have."
}

variable "bootstrap_sa" {
    type        = object({
        account_id = string
        name       = string
        email      = string
        unique_id  = string
    })
#    default     = ""
    description = "The details for the bootstrap service account."
}