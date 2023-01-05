resource "google_artifact_registry_repository" "third_party" {
  project       = var.project_id
  location      = "europe-west4"
  repository_id = "third-party"
  description   = "Registry for third-party images"
  format        = "DOCKER"
}