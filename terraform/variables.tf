# This is for declaring variables and it is type strong. If you have experience with programming then this is basic stuff
# These variables get values from terraform.tfvars
variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "region" {
  description = "Project region"
  type        = string
  default     = "europe-north1"
}

variable "cluster_location" {
  type    = string
  default = "europe-north1-a"
}

variable "second_cluster_location" {
  type    = string
  default = "europe-north1-b"
}