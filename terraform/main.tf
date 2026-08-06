# This block tells terraform which provider and version we are using and also that we are using Terraform Cloud. This is mandatory
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.41.0"
    }
  }
  cloud {
    organization = "sanderk_study"
    workspaces {
      name = "project_proof"
    }
  }
}

# This is provider configuration, This is mandatory
provider "google" {
  project = var.project_id
  region  = var.region
}

module "gke" {
    source = "./modules/gke"
    cluster_location = var.cluster_location
    second_cluster_location = var.second_cluster_location
    project_id = var.project_id
}