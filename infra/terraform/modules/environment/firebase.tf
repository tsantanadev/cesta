# Firebase: the project, its default Hosting site in front of Cloud Run, and the custom
# domain. Hosting content and rewrites are deployed by CI from hosting/firebase.json.
# Auth providers and Crashlytics are set up in the Firebase console (infra/README.md).

resource "google_firebase_project" "this" {
  provider   = google-beta
  project    = var.project_id
  depends_on = [google_project_service.apis]
}

resource "google_firebase_hosting_site" "default" {
  provider = google-beta
  project  = var.project_id
  site_id  = var.project_id # the default site, so firebase.json needs no site key

  depends_on = [google_firebase_project.this]
}

resource "google_firebase_hosting_custom_domain" "this" {
  provider      = google-beta
  project       = var.project_id
  site_id       = google_firebase_hosting_site.default.site_id
  custom_domain = var.domain

  # DNS is set up by hand from the required_dns_updates output.
  wait_dns_verification = false
}
