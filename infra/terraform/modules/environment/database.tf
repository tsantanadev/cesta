# Neon serverless Postgres in São Paulo (free plan) and the connection strings the
# backend and the migrations job read from Secret Manager. The Neon projects were
# created in the console and imported (envs/*/main.tf), because each environment's
# API key is scoped to its own project and can't create one.

resource "neon_project" "this" {
  name       = "cesta-${var.environment}"
  region_id  = "aws-sa-east-1"
  pg_version = 18 # keep in step with backend/internal/testkit/postgres.go

  # The free plan keeps at most 6 hours of history.
  history_retention_seconds = 21600

  # Neon's console defaults.
  branch {
    name          = "production"
    database_name = "neondb"
    role_name     = "neondb_owner"
  }
}

locals {
  # The service's pool is capped so max-instances x pool size stays well under Neon's
  # connection limits (ADR-0005). pgx reads pool_max_conns from the URL.
  pooled_url = neon_project.this.connection_uri_pooler
  database_urls = {
    "database-url"        = "${local.pooled_url}${strcontains(local.pooled_url, "?") ? "&" : "?"}pool_max_conns=5"
    "database-url-direct" = neon_project.this.connection_uri # goose holds a session-level lock
  }
}

resource "google_secret_manager_secret" "database" {
  for_each = local.database_urls

  project   = var.project_id
  secret_id = each.key

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "database" {
  for_each = local.database_urls

  secret      = google_secret_manager_secret.database[each.key].id
  secret_data = each.value
}

# Created by hand (infra/README.md): the Grafana Cloud OTLP auth header.
data "google_secret_manager_secret" "otel_headers" {
  project   = var.project_id
  secret_id = "otel-exporter-otlp-headers"
}

# Created by hand (infra/README.md): the Resend API key the backend sends
# Invitation emails with.
data "google_secret_manager_secret" "resend_api_key" {
  project   = var.project_id
  secret_id = "resend-api-key"
}
