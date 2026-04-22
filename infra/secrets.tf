resource "random_password" "admin_token" {
  count   = var.admin_token == null ? 1 : 0
  length  = 48
  special = false
}

locals {
  admin_token_value = var.admin_token != null ? var.admin_token : random_password.admin_token[0].result

  secrets = {
    google-api-key = var.google_api_key
    admin-token    = local.admin_token_value
    sentry-dsn     = var.sentry_dsn
  }
}

resource "google_secret_manager_secret" "this" {
  for_each  = local.secrets
  project   = google_project.this.project_id
  secret_id = each.key

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "this" {
  for_each    = local.secrets
  secret      = google_secret_manager_secret.this[each.key].id
  secret_data = each.value
}
