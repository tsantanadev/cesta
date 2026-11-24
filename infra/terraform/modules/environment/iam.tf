# Least-privilege service accounts: one per workload, each reading only its own secrets,
# and a deployer that GitHub Actions impersonates through OIDC (no keys).

resource "google_service_account" "backend" {
  project      = var.project_id
  account_id   = "cesta-backend"
  display_name = "Cesta backend (Cloud Run service)"
  depends_on   = [google_project_service.apis]
}

resource "google_service_account" "migrate" {
  project      = var.project_id
  account_id   = "cesta-migrate"
  display_name = "Cesta migrations (Cloud Run job)"
  depends_on   = [google_project_service.apis]
}

resource "google_service_account" "deployer" {
  project      = var.project_id
  account_id   = "cesta-deployer"
  display_name = "GitHub Actions deployer"
  depends_on   = [google_project_service.apis]
}

resource "google_secret_manager_secret_iam_member" "backend" {
  for_each = {
    database-url = google_secret_manager_secret.database["database-url"].id
    otel-headers = data.google_secret_manager_secret.otel_headers.id
  }

  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.backend.member
}

resource "google_secret_manager_secret_iam_member" "migrate" {
  secret_id = google_secret_manager_secret.database["database-url-direct"].id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.migrate.member
}

# --- CI ---------------------------------------------------------------------------

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
  depends_on                = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Actions OIDC"

  attribute_mapping = {
    "google.subject"          = "assertion.sub"
    "attribute.repository"    = "assertion.repository"
    "attribute.repository_id" = "assertion.repository_id"
    "attribute.environment"   = "assertion.environment"
    "attribute.ref"           = "assertion.ref"
  }

  # Only jobs of this repository, running from main in this GitHub environment.
  attribute_condition = join(" && ", [
    "assertion.repository_id == '${var.github_repository_id}'",
    "assertion.ref == 'refs/heads/main'",
    "assertion.environment == '${var.environment}'",
  ])

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "deployer_wif" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.environment/${var.environment}"
}

resource "google_project_iam_member" "deployer" {
  for_each = toset([
    "roles/run.developer",                     # deploy the service, update and run the migrations job
    "roles/firebasehosting.admin",             # firebase deploy --only hosting
    "roles/serviceusage.serviceUsageConsumer", # the Firebase CLI checks enabled APIs
  ])

  project = var.project_id
  role    = each.value
  member  = google_service_account.deployer.member
}

resource "google_artifact_registry_repository_iam_member" "deployer" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.writer"
  member     = google_service_account.deployer.member
}

# Deploying a revision or job execution "acts as" its runtime service account.
resource "google_service_account_iam_member" "deployer_acts_as" {
  for_each = {
    backend = google_service_account.backend.name
    migrate = google_service_account.migrate.name
  }

  service_account_id = each.value
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.deployer.member
}
