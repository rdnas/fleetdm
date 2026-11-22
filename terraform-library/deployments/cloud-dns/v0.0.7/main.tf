terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.12"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 8.12"
    }
  }

  backend "gcs" {}
}

provider "google" {
  project = var.service_project_id
  region  = var.region
  zone    = var.zone
}

# The upstream module still declares google-beta (reverse_lookup / service_directory zones).
provider "google-beta" {
  project = var.service_project_id
  region  = var.region
  zone    = var.zone
}
