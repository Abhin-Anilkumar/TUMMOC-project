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
# Firewall Rules
# ─────────────────────────────────────────

# Allow SSH access
resource "google_compute_firewall" "allow_ssh" {
  name    = "craftista-allow-ssh"
  network = google_compute_network.craftista_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["craftista-vm"]
  description   = "Allow SSH access to Craftista VMs"
}

# Allow HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name    = "craftista-allow-http"
  network = google_compute_network.craftista_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["craftista-vm", "http-server"]
  description   = "Allow HTTP traffic to Craftista VMs"
}

# Allow HTTPS traffic
resource "google_compute_firewall" "allow_https" {
  name    = "craftista-allow-https"
  network = google_compute_network.craftista_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["craftista-vm", "https-server"]
  description   = "Allow HTTPS traffic to Craftista VMs"
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

# Allow health check probes from GCP load balancer
resource "google_compute_firewall" "allow_health_check" {
  name    = "craftista-allow-health-check"
  network = google_compute_network.craftista_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # GCP health check IP ranges
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["craftista-vm"]
  description   = "Allow GCP load balancer health checks"
}

# Allow application ports (for debugging/direct access)
resource "google_compute_firewall" "allow_app_ports" {
  name    = "craftista-allow-app-ports"
  network = google_compute_network.craftista_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3000", "5000", "8080", "9090", "3001"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["craftista-vm"]
  description   = "Allow application ports for internal access (Prometheus: 9090, Grafana: 3001)"
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
