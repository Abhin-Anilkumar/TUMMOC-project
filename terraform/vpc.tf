# ============================================
# Craftista - VPC, Subnets & Firewall Rules
# ============================================

# ─────────────────────────────────────────
# VPC Network
# ─────────────────────────────────────────
resource "google_compute_network" "craftista_vpc" {
  name                    = "craftista-vpc"
  auto_create_subnetworks = false
  description             = "VPC network for Craftista application"
}

# ─────────────────────────────────────────
# Subnet
# ─────────────────────────────────────────
resource "google_compute_subnetwork" "craftista_subnet" {
  name          = "craftista-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.craftista_vpc.id

  # Enable private Google access for GCR/GAR
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# ─────────────────────────────────────────
# Firewall Rules (Locked Down - No Public IP)
# ─────────────────────────────────────────

# Allow SSH via IAP only (gcloud compute ssh uses this)
resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "craftista-allow-ssh-iap"
  network = google_compute_network.craftista_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range — only way to SSH into VMs
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["craftista-vm"]
  description   = "Allow SSH via IAP tunnel only (gcloud compute ssh)"
}

# Allow HTTP from GCP Load Balancer only
resource "google_compute_firewall" "allow_lb_traffic" {
  name    = "craftista-allow-lb-traffic"
  network = google_compute_network.craftista_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # GCP Load Balancer + Health Check IP ranges
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["craftista-vm"]
  description   = "Allow HTTP traffic from GCP Load Balancer and health checks only"
}

# Allow internal communication between VMs
resource "google_compute_firewall" "allow_internal" {
  name    = "craftista-allow-internal"
  network = google_compute_network.craftista_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["craftista-vm"]
  description   = "Allow internal communication between Craftista VMs"
}

# ─────────────────────────────────────────
# Cloud Router & NAT (for outbound internet)
# ─────────────────────────────────────────
resource "google_compute_router" "craftista_router" {
  name    = "craftista-router"
  region  = var.region
  network = google_compute_network.craftista_vpc.id
}

resource "google_compute_router_nat" "craftista_nat" {
  name                               = "craftista-nat"
  router                             = google_compute_router.craftista_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
