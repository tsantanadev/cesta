# The backend service and the migrations job. Terraform owns their configuration;
# CI owns the image (deploy.yml), so image changes are ignored here.

locals {
  # Placeholder images used until CI's first deploy.
  placeholder_service_image = "us-docker.pkg.dev/cloudrun/container/hello"
  placeholder_job_image     = "us-docker.pkg.dev/cloudrun/container/job"
}

resource "google_artifact_registry_repository" "images" {
  project       = var.project_id
  location      = var.region
  repository_id = "cesta"
  format        = "DOCKER"
  description   = "Backend images. dev builds them; prod receives copies by digest."

  # Stay inside the 0.5 GB free storage.
  cleanup_policy_dry_run = false
  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }
  cleanup_policies {
    id     = "delete-old"
    action = "DELETE"
    condition {
      older_than = "2592000s" # 30 days
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_artifact_registry_repository_iam_member" "image_readers" {
  for_each = toset(var.image_reader_members)

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.reader"
  member     = each.value
}

resource "google_cloud_run_v2_service" "backend" {
  project  = var.project_id
  name     = "cesta-backend"
  location = var.region

  # Firebase Hosting reaches the service through its run.app URL, so ingress stays
  # open and the default URL stays on; the backend rejects requests that didn't come
  # through Hosting (PUBLIC_HOST, backend/internal/platform/hosting).
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = google_service_account.backend.email
    max_instance_request_concurrency = 80

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      image = local.placeholder_service_image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = true # request-based billing: $0 when idle
        startup_cpu_boost = false
      }

      env {
        name  = "PUBLIC_HOST"
        value = var.domain
      }
      env {
        name  = "LOG_LEVEL"
        value = var.log_level
      }
      env {
        name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
        value = var.otel_exporter_otlp_endpoint
      }
      env {
        name  = "OTEL_RESOURCE_ATTRIBUTES"
        value = "deployment.environment.name=${var.environment}"
      }
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database["database-url"].secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "OTEL_EXPORTER_OTLP_HEADERS"
        value_source {
          secret_key_ref {
            secret  = data.google_secret_manager_secret.otel_headers.secret_id
            version = "latest"
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].revision,
      template[0].labels,
      client,
      client_version,
    ]
  }

  depends_on = [
    google_secret_manager_secret_version.database,
    google_secret_manager_secret_iam_member.backend,
  ]
}

# Firebase Hosting rewrites call the service anonymously.
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_job" "migrate" {
  project             = var.project_id
  name                = "cesta-migrate"
  location            = var.region
  deletion_protection = false

  template {
    task_count = 1

    template {
      service_account = google_service_account.migrate.email
      max_retries     = 0
      timeout         = "300s"

      containers {
        image = local.placeholder_job_image
        args  = ["migrate"]

        env {
          name = "DATABASE_URL"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.database["database-url-direct"].secret_id
              version = "latest"
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
      template[0].labels,
      client,
      client_version,
    ]
  }

  depends_on = [
    google_secret_manager_secret_version.database,
    google_secret_manager_secret_iam_member.migrate,
  ]
}
