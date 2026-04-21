output "project_id" {
  value       = google_project.this.project_id
  description = "GCP project id"
}

output "function_url" {
  value       = google_cloudfunctions2_function.server.service_config[0].uri
  description = "HTTPS URL of the Cloud Function (Gen 2)"
}

output "admin_token" {
  value       = local.admin_token_value
  sensitive   = true
  description = "Bearer token for /admin/* routes (used by the post-deploy migration step)"
}

output "ios_app_id" {
  value       = google_firebase_apple_app.ios.app_id
  description = "Firebase iOS app id"
}

output "ios_plist_path" {
  value       = local_file.google_service_info_plist.filename
  description = "Local path of the generated GoogleService-Info.plist"
}
