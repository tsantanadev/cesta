output "project_number" {
  value = data.google_project.this.number
}

output "deployer_service_account" {
  description = "GitHub environment variable GCP_DEPLOYER_SA."
  value       = google_service_account.deployer.email
}

output "workload_identity_provider" {
  description = "GitHub environment variable GCP_WORKLOAD_IDENTITY_PROVIDER."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "image_repository" {
  description = "GitHub environment variable IMAGE_REPOSITORY."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}/backend"
}

output "service_url" {
  description = "The run.app URL. Requests to it that bypass Firebase Hosting get 404."
  value       = google_cloud_run_v2_service.backend.uri
}

output "required_dns_updates" {
  description = "DNS records to create for the custom domain."
  value       = google_firebase_hosting_custom_domain.this.required_dns_updates
}

output "kill_switch_topic" {
  description = "Publish a fake budget notification here to test the kill switch."
  value       = var.kill_switch_enabled ? google_pubsub_topic.kill_switch[0].id : null
}

output "android_config_file" {
  description = "google-services.json for the Android app (base64). Not secret: Firebase client config is public."
  value       = data.google_firebase_android_app_config.cesta.config_file_contents
}

output "apple_config_file" {
  description = "GoogleService-Info.plist for the iOS app (base64). Not secret: Firebase client config is public."
  value       = data.google_firebase_apple_app_config.cesta.config_file_contents
}
