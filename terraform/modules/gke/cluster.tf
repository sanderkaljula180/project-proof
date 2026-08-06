resource "google_container_cluster" "primary" {
    name = "primary"
    # This is kinda important. You can choose between region or zone.
    # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#location-1
    location = var.cluster_location
    # I will create my own node pool
    remove_default_node_pool = true
    # Well, the reasoning why I still have to give initial node count, even though it is remove, is because you can't create cluster with zero nodes
    initial_node_count = 1
    # Why self_link? https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#network-1
    network = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link
    # Logging and monitoring for Google Cloud Monitoring
    logging_service = "logging.googleapis.com/kubernetes"
    monitoring_service = "monitoring.googleapis.com/kubernetes"
    # This gives my pods real IPs from my subnet secondary ranges
    networking_mode = "VPC_NATIVE"

    release_channel {
      channel = "REGULAR"
    }

    # This lets my Kubernetes service accounts connect to Google Cloud services, like Cloud SQL.
    workload_identity_config {
      workload_pool = "${var.project_id}.svc.id.goog"
    }

    # This connects my GKE cluster to my secondary ranges
    ip_allocation_policy {
        cluster_secondary_range_name  = "gke-pods-secondary-range"
        services_secondary_range_name = "gke-services-secondary-range"
    }

    private_cluster_config {
        enable_private_nodes    = true
        # If you have VPN or somekind of jump host
        enable_private_endpoint = false
        master_ipv4_cidr_block  = "172.16.0.0/28"
    }
}

