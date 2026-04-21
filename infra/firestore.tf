resource "google_firebaserules_ruleset" "firestore" {
  provider = google-beta
  project  = google_project.this.project_id

  source {
    files {
      name    = "firestore.rules"
      content = file("${path.root}/../firestore.rules")
    }
  }

  depends_on = [google_firestore_database.default]
}

resource "google_firebaserules_release" "firestore" {
  provider     = google-beta
  project      = google_project.this.project_id
  name         = "cloud.firestore"
  ruleset_name = "projects/${google_project.this.project_id}/rulesets/${google_firebaserules_ruleset.firestore.name}"
}

locals {
  firestore_indexes = jsondecode(file("${path.root}/../firestore.indexes.json")).indexes
}

resource "google_firestore_index" "composite" {
  for_each = { for i, idx in local.firestore_indexes : i => idx }

  provider    = google-beta
  project     = google_project.this.project_id
  database    = google_firestore_database.default.name
  collection  = each.value.collectionGroup
  query_scope = each.value.queryScope

  dynamic "fields" {
    for_each = each.value.fields
    content {
      field_path = fields.value.fieldPath
      order      = try(fields.value.order, null)
    }
  }
}
