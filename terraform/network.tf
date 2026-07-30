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
  # This is for reaching my Google API's privately. Like Secret Manager and Artifact Registry etc
  private_ip_google_access = true
  # These two create me two secondary ip ranges for my k8s pods and services. Later I am going to configure GKE to use them
  secondary_ip_range {
    range_name = "gke-pods-secondary-range"
    ip_cidr_range = "10.4.0.0/16"
  }
  secondary_ip_range {
    range_name = "gke-services-secondary-range"
    ip_cidr_range = "10.8.0.0/20"
  }
}

# Create reserved range for bridge for Cloud SQL connection
resource "google_compute_global_address" "reserved_range_for_cloud_sql" {
  name          = "reserved-range-for-cloud-sql"
  address_type  = "INTERNAL"
  # VPC_PEERING is for connecting two separated networks
  purpose       = "VPC_PEERING"
  network       = google_compute_network.vpc.id
  # This one didn't have ip_cidr_range argument, so if you want to give it a range, you have to use prefix_length
  prefix_length = 16
  address       = "10.10.0.0"
}

# Create private service access/private connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  # Provider peering service that is managing peering connectivity for a service provider organization
  service                 = "servicenetworking.googleapis.com"
  # Then you point it at the reserver range
  reserved_peering_ranges = [google_compute_global_address.reserved_range_for_cloud_sql.name]
  # I read that service networking connections are hard to destroy so this was suggestion to be added if i destory
  deletion_policy         = "ABANDON"
}

# Create router
resource "google_compute_router" "router" {
    name = "gke-router"
    network = google_compute_network.vpc.id
    region = var.region
}

# Create NAT
resource "google_compute_router_nat" "nat" {
  name                               = "gke-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  # Going to keep auto option because I only use this for argocd -> github connection and there is no whitelist
  nat_ip_allocate_option             = "AUTO_ONLY"
  # Keep all ip ranges because argo will be in a pod and pods use secondary range
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

    # Just in case if argo cant connect to github
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

