# Firebase Authentication (ADR-0003): email + password sign-in, the authorized
# domains, and the Android and iOS apps that sign in. The Google provider needs
# an OAuth web client that Terraform can't create, so it is enabled in the
# Firebase console (infra/auth-setup.sh), which creates the client for us.
#
# Managing this config upgrades the project to Firebase Authentication with
# Identity Platform. Email + password and Google sign-in stay free up to
# 50,000 monthly active users.

resource "google_identity_platform_config" "auth" {
  project = var.project_id

  sign_in {
    allow_duplicate_emails = false

    email {
      enabled           = true
      password_required = true
    }
  }

  # Password reset emails link back to these domains.
  authorized_domains = [
    "localhost",
    "${var.project_id}.firebaseapp.com",
    "${var.project_id}.web.app",
    var.domain,
  ]

  depends_on = [google_project_service.apis]
}

resource "google_firebase_android_app" "cesta" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Cesta (Android)"
  package_name = var.app_id

  # Google sign-in on Android only works for builds signed with a registered key.
  sha1_hashes   = var.android_sha1_hashes
  sha256_hashes = var.android_sha256_hashes

  depends_on = [google_firebase_project.this]
}

resource "google_firebase_apple_app" "cesta" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Cesta (iOS)"
  bundle_id    = var.app_id
  team_id      = var.apple_team_id

  depends_on = [google_firebase_project.this]
}

data "google_firebase_android_app_config" "cesta" {
  provider = google-beta
  project  = var.project_id
  app_id   = google_firebase_android_app.cesta.app_id
}

data "google_firebase_apple_app_config" "cesta" {
  provider = google-beta
  project  = var.project_id
  app_id   = google_firebase_apple_app.cesta.app_id
}
