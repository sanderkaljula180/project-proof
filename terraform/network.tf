# Creates VPC for my Artifact Registry, Cloud SQL, Secret Manager and subnet
resource "google_compute_network" "vpc" {
  name                    = "main-vpc"
  # If this is true then GCP creates automatically subnets wihtout asking. Next block shows that I create my own subnet, so it should stay false
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Creates subnet in my VPC
resource "google_compute_subnetwork" "subnet" {
  name          = "main-subnet"
  # This gets the vpc id above resource block and this subnet will be created in that VPC
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = "10.0.0.0/24"
  project       = var.project_id
}