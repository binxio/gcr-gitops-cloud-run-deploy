resource "google_service_account" "example" {
  project      = var.project_id
  account_id   = "example-sa"
  display_name = "Example application Service Account"
}

resource "google_artifact_registry_repository_iam_member" "third_party_reader_example" {
  project    = var.project_id
  location   = "europe-west4"
  repository = "third-party"

  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${google_service_account.example.email}"
}

resource "google_cloud_run_service" "example" {
  project                    = var.project_id
  location                   = "europe-west4"
  name                       = "example"
  autogenerate_revision_name = true

  template {
    metadata {
      labels = {
        "app" = "example"
        "env" = "production"
      }
    }

    spec {
      service_account_name = google_service_account.example.email

      containers {
        image = var.example_image

        ports {
          name           = "http1"
          container_port = 8080
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "example" {
  project  = var.project_id
  location = "europe-west4"
  service  = google_cloud_run_service.example.name

  role   = "roles/run.invoker"
  member = "allUsers"
}