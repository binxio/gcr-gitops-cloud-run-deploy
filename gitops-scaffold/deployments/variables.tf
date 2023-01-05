variable "project_id" {
  description = "Project to deploy to."
  type        = string
  default     = "my-project"
}

variable "example_image" {
  description = "Example container image to deploy. Defaults to gcr.io/cloudrun/placeholder:latest"
  type        = string
  default     = "gcr.io/cloudrun/placeholder:latest"
}