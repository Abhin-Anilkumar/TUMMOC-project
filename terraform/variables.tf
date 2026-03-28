# ============================================
# Craftista - Terraform Variables
# ============================================

# ─────────────────────────────────────────
# GCP Project Configuration
# ─────────────────────────────────────────
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "The GCP zone for resources"
  type        = string
  default     = "asia-south1-a"
}

variable "credentials_file" {
  description = "Path to GCP service account credentials JSON file"
  type        = string
  default     = "credentials.json"
}

# ─────────────────────────────────────────
# Compute Configuration
# ─────────────────────────────────────────
variable "machine_type" {
  description = "GCE machine type for application VMs"
  type        = string
  default     = "e2-medium"
}

variable "vm_count" {
  description = "Number of application VM instances"
  type        = number
  default     = 2
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 30
}

variable "boot_disk_type" {
  description = "Boot disk type (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-balanced"
}

variable "vm_image" {
  description = "VM operating system image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

# ─────────────────────────────────────────
# Network Configuration
# ─────────────────────────────────────────
variable "subnet_cidr" {
  description = "CIDR range for the application subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# ─────────────────────────────────────────
# SSH Configuration
# ─────────────────────────────────────────
variable "ssh_user" {
  description = "SSH username for VM access"
  type        = string
  default     = "craftista"
}

variable "ssh_pub_key" {
  description = "SSH public key content (run: cat ~/.ssh/id_rsa.pub)"
  type        = string
  default     = ""
}

# ─────────────────────────────────────────
# Tags & Labels
# ─────────────────────────────────────────
variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    project     = "craftista"
    managed_by  = "terraform"
    team        = "devops"
  }
}
