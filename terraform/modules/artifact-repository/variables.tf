variable "project" {
    type = object({
        id         = string
        number     = string
    })
#    default     = ""
    description = "A collection of the project details."
}

variable "cicd_runner" {
    type = object({
        account_id = string
        name       = string
        email      = string
        unique_id  = string
    })
#    default     = ""
    description = "A collection of the cicd account's details."
}

variable "region" {
    type        = string
#    default     = ""
    description = ""
}

variable "github_org" {
    type        = string
#    default     = ""
    description = ""
}

variable "github_repo" {
    type        = string
#    default     = ""
    description = ""
}

variable "repository_id" {
    type        = string
#   default     = ""
    description = ""
}

variable "cicd_workload_id" {
    type = string
#   default = ""
    description = "The auth pool used for this workload pool."
}

variable "python" {
  type = object({
    version  = string
    packages = map(string)
  })
  description = "Python version and PyPI package constraints for the project"
}