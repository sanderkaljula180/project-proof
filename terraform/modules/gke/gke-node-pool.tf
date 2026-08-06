# So this has node pool with its Google Service Account

# SA for nodes in pool
resource "google_service_account" "gke-nodes-sa" {
  account_id = "gke-nodes-sa"
}

# Roles for SA
resource "google_project_iam_member" "node_sa_roles" {
  for_each = toset([
    "roles/artifactregistry.reader",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke-nodes-sa.email}"
}

# Node pool
resource "google_container_node_pool" "primary_nodes" {
  name     = "primary-node-pool"
  cluster  = google_container_cluster.primary.id
  location = var.cluster_location

  # Autoscaling — scales nodes with load, can scale down to save cost
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 30
    disk_type    = "pd-standard"

    # Custom minimal service account for the nodes
    service_account = google_service_account.gke-nodes-sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Required for Workload Identity to work on pods
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  # Keep nodes healthy and patched
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}