# Configure Terraform service account
data "google_service_account" "terraform_sa" {
  project    = var.project_id
  account_id = "terraform-sa"
}

resource "google_project_iam_member" "project_owner_terraform" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}


# Configure GitOps deployment account
resource "google_service_account" "gitops_deployment" {
  project      = var.project_id
  account_id   = "gitops-deployment-sa"
  display_name = "GitOps repo deployment service account"
}

# Grant permissions to commit to GitOps repo, required to commit latest image tags
resource "google_sourcerepo_repository_iam_member" "gitops_source_writer_gitops_deployment" {
  project    = var.project_id
  repository = google_sourcerepo_repository.gitops.name
  role       = "roles/source.writer"
  member     = "serviceAccount:${google_service_account.gitops_deployment.email}"
}

# Grant permissions to write Cloud Build logs
resource "google_project_iam_member" "project_logs_writer_gitops_deployment" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gitops_deployment.email}"
}

# Allow GitOps deployment account to impersonate Terraform
resource "google_service_account_iam_member" "terraform_impersonate_gitops_deployment" {
  service_account_id = google_service_account.terraform_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.gitops_deployment.email}"
}


# Listen for Artifact Registry notifications, see: https://cloud.google.com/artifact-registry/docs/configure-notifications#gcloud
resource "google_pubsub_topic" "gcr" {
  project = var.project_id
  name    = "gcr"

  message_retention_duration = "86600s"
  message_storage_policy {
    allowed_persistence_regions = [
      "europe-west4",
    ]
  }
}


# Configure build triggers that commit latest image version to GitOps repo
locals {
  triggering_images = {
    example = {
      image_name    = "europe-west4-docker.pkg.dev/${var.project_id}/third-party/example"
      variable_name = "example_image"
    }
  }
}

resource "google_cloudbuild_trigger" "gitops_application_update" {
  for_each = local.triggering_images

  project = var.project_id
  name    = "gitops-${each.key}-ci"

  service_account = google_service_account.gitops_deployment.id

  pubsub_config {
    topic = google_pubsub_topic.gcr.id
  }

  build {
    source {
      repo_source {
        project_id = var.project_id
        repo_name  = google_sourcerepo_repository.gitops.name
        branch_name = "main"
      }
    }

    step {
        name = "gcr.io/cloud-builders/git"
        entrypoint = "bash"
        args = [
            "-c",
            <<-EOT
            git config --local user.email "gitops-deploy@binx.io"
            git config --local user.name "GitOps Deploy Bot"

            git fetch
            git switch main

            echo "${each.value.variable_name} = \"$${_IMAGE_DIGEST}\"" > deployments/variables.${each.key}.auto.tfvars
            
            git add deployments/variables.${each.key}.auto.tfvars
            git commit -m "Set ${each.key} version to $${_IMAGE_DIGEST}"

            git push
            EOT
        ]
    }

    step {
      name = "hashicorp/terraform:1.2.9"
      dir  = "deployments"
      args = ["init", "-no-color"]
    }

    step {
      name = "hashicorp/terraform:1.2.9"
      dir  = "deployments"
      args = ["apply", "-no-color", "-lock-timeout=300s", "-auto-approve"]
    }
  }

  substitutions = {
    _ACTION       = "$(body.message.data.action)"
    _IMAGE_DIGEST = "$(body.message.data.digest)"
  }

  filter = "_ACTION.matches('INSERT') && _IMAGE_DIGEST.startsWith('${each.value.image_name}@')"
}
