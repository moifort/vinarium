resource "google_identity_platform_config" "this" {
  provider                   = google-beta
  project                    = google_project.this.project_id
  autodelete_anonymous_users = false

  sign_in {
    allow_duplicate_emails = false

    email {
      enabled           = false
      password_required = false
    }

    anonymous {
      enabled = false
    }
  }

  depends_on = [google_firebase_project.this]
}

resource "google_identity_platform_oauth_idp_config" "apple" {
  provider     = google-beta
  project      = google_project.this.project_id
  name         = "oidc.apple.com"
  display_name = "Apple"
  enabled      = true
  client_id    = var.apple_services_id
  issuer       = "https://appleid.apple.com"

  client_secret = jsonencode({
    teamId     = var.apple_team_id
    keyId      = var.apple_key_id
    privateKey = file(var.apple_private_key_path)
  })

  depends_on = [google_identity_platform_config.this]
}
