terraform {
  backend "gcs" {
    impersonate_service_account = "terraform-sa@my-project.iam.gserviceaccount.com"
    bucket                      = "my-project-terraform"
    prefix                      = "production"
  }

  required_version = "~> 1.2.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.34"
    }
  }
}

provider "google" {
  impersonate_service_account = "terraform-sa@my-project.iam.gserviceaccount.com"
}
