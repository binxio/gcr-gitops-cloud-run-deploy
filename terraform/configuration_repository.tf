resource "google_sourcerepo_repository" "gitops" {
  project = var.project_id
  name    = "gitops"
}
