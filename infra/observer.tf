# A read-only account for watching production from outside it: the daily health routine on
# the Mac reads logs, metrics, scheduler state and Firestore through it, so it never depends on
# a personal gcloud login that expires. Viewer roles only — nothing it holds can change the
# project. Its key is created by hand and kept off the repository and the state
# (~/.config/vinarium-observer), since a key made here would sit in plain text in the state.
#
# The bill (dataset billing_export) is read through shiori-observer, which already holds READER
# on that dataset, so this account gets no BigQuery role.
resource "google_service_account" "observer" {
  project      = google_project.this.project_id
  account_id   = "vinarium-observer"
  display_name = "Vinarium read-only observer"
}

resource "google_project_iam_member" "observer" {
  for_each = toset([
    "roles/logging.viewer",
    "roles/monitoring.viewer",
    "roles/cloudscheduler.viewer",
    "roles/cloudfunctions.viewer",
    "roles/run.viewer",
    "roles/datastore.viewer",
  ])

  project = google_project.this.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.observer.email}"
}
