provider "google" {
    project = var.project_id
    region = var.region
    zone = var.zone
    credentials = var.credentials_json
}

resource "google_container_cluster" "project_cluster" {
    name     = var.cluster_name
    location = var.region
    remove_default_node_pool = true
    initial_node_count       = 1
    deletion_protection      = false

    workload_identity_config {
        workload_pool = "${var.project_id}.svc.id.goog"
    }
}

resource "google_container_node_pool" "node_pool" {
    name       = var.node_pool
    location   = var.region
    cluster    = google_container_cluster.project_cluster.self_link
    node_count = 1

    node_config {
        preemptible  = false
        machine_type = var.machine_type
        disk_size_gb = 350
    }
}

resource "null_resource" "deploy_services" {
    depends_on = [
        google_container_node_pool.node_pool
    ]
    
    provisioner "local-exec" {
        command = "gcloud container clusters get-credentials ${google_container_cluster.project_cluster.name} --region=${google_container_cluster.project_cluster.location}"   
    }

    provisioner "local-exec" {
        command = "kubectl apply -f ./scripts/jupyter"
    }

    provisioner "local-exec" {
        command = "kubectl apply -f ./scripts/spark"
    }

    provisioner "local-exec" {
        command = "kubectl apply -f ./scripts/hadoop"
    }

    provisioner "local-exec" {
        command = "kubectl apply -f ./scripts/jenkins"
    }

    provisioner "local-exec" {
        command = "kubectl apply -f ./scripts/frontend"
    }
}

output "cluster_location" {
  description = "Cluster Location"
  value       = resource.google_container_cluster.final_project_clusterr.location
}

variable "project_id" {
  type        = string
  description = "Google Project ID"
}

variable "cluster_name" {
  type        = string
  description = "Cluster Name"
}

variable "region" {
  type        = string
  description = "Default Region"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "Default Zone"
  default     = "us-central1-c"
}

variable "node_pool" {
    type        = string
    description = "Name of Node Pool"
    default     = "nodepool"
}

variable "machine_type" {
  type        = string
  description = "Machine Type"
  default     = "e2-standard-2"
}

variable "credentials_json" {
  type        = string
  description = "Credentials file"
  default     = "./creds.json"
}