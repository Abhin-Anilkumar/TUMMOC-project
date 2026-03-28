# ============================================
# Craftista - GCP Terraform Configuration
# Provider & Backend Configuration
# ============================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Remote state in GCS (uncomment after creating the bucket)
  # backend "gcs" {
  #   bucket = "craftista-terraform-state"
  #   prefix = "terraform/state"
  # }
}

# ─────────────────────────────────────────
# Google Cloud Provider
# ─────────────────────────────────────────
provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file(var.credentials_file)
}
