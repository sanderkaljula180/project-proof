# This is for SA for my app/pods

resource "google_service_account" "app" {
  account_id = "app"
}

resource "google_project_iam_member" "app_roles" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.app.email}"
}

# This lets me bind my app SA to my pods later in my manifest file using kind: ServiceAccount 
resource "google_service_account_iam_member" "app_bind" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/app-ksa]"
}