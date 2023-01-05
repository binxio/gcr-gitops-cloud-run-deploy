# Continuous Deployment for Cloud Run on container image update

This repository configures Continuous deployment for an example Cloud Run solution based on container image updates. The solution is deployed using Terraform in a GitOps way.

## Components

* Terraform
    This deploys the GitOps repository to your project and configures build triggers that update the repository as soon as a container image is updated.

* gitops-scaffold
    Example content to initialize the GitOps repository for application deployment.

* example-application
    Example Dockerfile to trigger application deployment

## Deployment

1. Deploy the necessary infrastructure to enable CI/CD: GitOps repo, Artifact Registry and Cloud Build triggers.

    ```bash
    cd terraform
    terraform init
    terraform apply
    ```

2. Bootstrap the GitOps repo

    ```bash
    gcloud source repos clone gitops --project my-project
    mv gitops-scaffold/* gitops/
    cd gitops
    git switch main
    git add .
    git commit -m "Initialized gitops repository."
    git push origin/main
    ```

3. Publish the example app to trigger a deployment

    ```bash
    cd example-application
    docker build -t europe-west4-docker.pkg.dev/my-project/third-party/example .
    docker push europe-west4-docker.pkg.dev/my-project/third-party/example
    ```
