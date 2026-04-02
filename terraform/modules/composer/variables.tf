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

variable "composer_env_name" {
  type        = string
#  default     = "composer-data-platform"
  description = ""
}

variable "composer_sa_name" {
  type        = string
#  default     = "composer-runtime-sa"
  description = ""
}

variable "image_version" {
  type        = string
#  default     = "composer-3-airflow-2.10.5-build.29"
  description = ""
}

variable "python" {
  type = object({
    version  = string
    packages = map(string)
  })
  description = "Python version and PyPI package constraints for the project"
}

variable "env_variables" {
  type        = map(string)
#  default     = {
#       ENV        = "dev"
#       PROJECT_ID = "replace-me"
#  }
  description = ""
}

variable "airflow_config_overrides" {
  type        = map(string)
#  default     = {
#        "core-dags_are_paused_at_creation" = "true"
#        "scheduler-catchup_by_default"     = "false"
#  }
  description = ""
}

variable "labels" {
  type        = map(string)
#  default     = {
#       managed_by = "terraform"
#       platform   = "composer"
#  }
  description = ""
}