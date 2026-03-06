variable "project_id" {
    type = string
#    default = ""
    description = "The project id for the dev environment, assuming environment separation is codified in projects."
}

variable "raw_bucket_name" {
    type = string
#    default = ""
    description = "The raw landing zone's bucket name for the dev environment."
}