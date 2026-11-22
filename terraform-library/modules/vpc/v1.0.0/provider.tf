terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.12"
    }
  }
}

provider "google" {
  credentials = var.credentials != "" ? var.credentials : null
  project     = var.project_id
  region      = var.region
}
