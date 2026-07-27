# Enabling needed API's through google_project_service.
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "dns.googleapis.com",
    "monitoring.googleapis.com",
  ])
  project = var.project_id
  service = each.value
  # I will probably destroy my infrastructure multiple times but I want those API's enabled after destroy
  disable_on_destroy = false
}