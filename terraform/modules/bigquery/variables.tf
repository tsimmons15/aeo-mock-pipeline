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

variable "raw_dataset_id" {
  type    = string
  default = "analytics_wh"
}

variable "core_dataset_id" {
  type    = string
  default = "analytics_wh"
}

variable "analytics_mart_dataset_id" {
  type    = string
  default = "analytics_wh"
}

variable "dataset_location" {
  type    = string
  default = "US"
}

variable "environment" {
  type    = string
  default = "dev"
}

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
