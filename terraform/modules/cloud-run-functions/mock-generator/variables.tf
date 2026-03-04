#####################################################################
# Mock Generator Inputs
#####################################################################

variable "project_id"      { 
    type        = string
#    default     = ""
    description = "The project id this module will be deployed to"
}

variable "region"          { 
    type        = string 
    default     = "us-east1"
    description = "The region this module will be deployed to"
}

variable "pubsub_topic_id" { 
    type        = string
    default     = "aeo-rt-events"
    description = "The pubsub topic this module is supposed to publish to"
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
#    default     = "${path.module}/../../app/mock-generator"
    description = "The source directory that contains main.py, requirements.txt"
}