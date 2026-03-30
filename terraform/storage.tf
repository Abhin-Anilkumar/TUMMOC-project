# ============================================
# Craftista - GCS Storage Buckets
# ============================================

# ─────────────────────────────────────────
# Terraform State Bucket
# ─────────────────────────────────────────
resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_id}-craftista-tf-state"
  location      = var.region
  force_destroy = false

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false
  }

  # Enable versioning for state history
  versioning {
    enabled = true
  }

  # Lifecycle rule - keep 30 days of state versions
  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  # Encryption
  uniform_bucket_level_access = true

  labels = var.labels
}

# ─────────────────────────────────────────
# Application Assets Bucket (Optional)
# ─────────────────────────────────────────
resource "google_storage_bucket" "app_assets" {
  name          = "${var.project_id}-craftista-assets"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["Content-Type"]
    max_age_seconds = 3600
  }

  labels = var.labels
}

# ─────────────────────────────────────────
# Artifact Registry Repository
# ─────────────────────────────────────────
resource "google_artifact_registry_repository" "craftista_repo" {
  location      = var.region
  repository_id = "craftista"
  description   = "Docker repository for Craftista application images"
  format        = "DOCKER"

  labels = var.labels
}
