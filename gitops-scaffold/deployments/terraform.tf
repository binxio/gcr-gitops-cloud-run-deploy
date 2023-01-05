terraform {
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
