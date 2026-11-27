# The daily purge of Lists deleted more than 30 days ago (`cesta purge`). A Cloud
# Run job rather than an endpoint or an in-process ticker: the service scales to
# zero with CPU throttled outside requests, and package hosting 404s requests that
# don't come through Firebase Hosting. Reads already hide such Lists, so a late or
# missed run is invisible to Users. CI owns the image (deploy.yml).

resource "google_cloud_run_v2_job" "purge" {
  project             = var.project_id
  name                = "cesta-purge"
  location            = var.region
  deletion_protection = false

  template {
    task_count = 1

    template {
      # Same database access as the service (pooled URL, DML only).
      service_account = google_service_account.backend.email
      max_retries     = 1
      timeout         = "300s"

      containers {
        image = local.placeholder_job_image
        args  = ["purge"]

        env {
          name  = "LOG_LEVEL"
          value = var.log_level
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
    google_secret_manager_secret_iam_member.backend,
  ]
}

resource "google_service_account" "scheduler" {
  project      = var.project_id
  account_id   = "cesta-scheduler"
  display_name = "Cesta Cloud Scheduler (runs the purge job)"
  depends_on   = [google_project_service.apis]
}

resource "google_cloud_run_v2_job_iam_member" "scheduler_runs_purge" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.purge.name
  role     = "roles/run.invoker"
  member   = google_service_account.scheduler.member
}

# Cloud Scheduler free tier: 3 jobs per billing account.
resource "google_cloud_scheduler_job" "purge" {
  project          = var.project_id
  region           = var.region
  name             = "cesta-purge-daily"
  description      = "Runs the cesta-purge job: removes Lists deleted more than 30 days ago."
  schedule         = "0 4 * * *"
  time_zone        = "America/Sao_Paulo"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${google_cloud_run_v2_job.purge.name}:run"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  depends_on = [
    google_project_service.apis,
    google_cloud_run_v2_job_iam_member.scheduler_runs_purge,
  ]
}
