# ============================================
# Craftista - Compute Engine VMs (Demo Specs)
# e2-small | 1 VM | 10GB boot + 35GB data disk
# ============================================

# ─────────────────────────────────────────
# Startup Script (reads from external file)
# ─────────────────────────────────────────
locals {
  startup_script = file("${path.module}/../scripts/docker-install.sh")
}

# ─────────────────────────────────────────
# Additional Data Disk (35GB)
# ─────────────────────────────────────────
resource "google_compute_disk" "craftista_data" {
  count = var.vm_count
  name  = "craftista-data-disk-${count.index + 1}"
  type  = "pd-standard"
  size  = var.data_disk_size
  zone  = var.zone

  labels = var.labels
}

# ─────────────────────────────────────────
# Compute Engine VM Instances
# ─────────────────────────────────────────
resource "google_compute_instance" "craftista_vm" {
  count        = var.vm_count
  name         = "craftista-vm-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["craftista-vm", "http-server", "https-server"]

  labels = merge(var.labels, {
    instance    = "vm-${count.index + 1}"
    environment = var.environment
  })

  # Boot disk (minimal 10GB)
  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  # Attached 35GB data disk
  attached_disk {
    source      = google_compute_disk.craftista_data[count.index].id
    device_name = "craftista-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.craftista_subnet.id
    # No access_config = No public IP (access via LB + IAP SSH only)
  }

  metadata = var.ssh_pub_key != "" ? {
    ssh-keys = "${var.ssh_user}:${var.ssh_pub_key}"
  } : {}

  metadata_startup_script = local.startup_script

  # Allow the VM to access GCP APIs (for Artifact Registry)
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  # Prevent terraform from recreating on metadata changes
  lifecycle {
    ignore_changes = [metadata_startup_script]
  }
}

# ─────────────────────────────────────────
# Instance Group (for Load Balancer backend)
# ─────────────────────────────────────────
resource "google_compute_instance_group" "craftista_group" {
  name        = "craftista-instance-group"
  description = "Craftista application VM instance group"
  zone        = var.zone

  instances = google_compute_instance.craftista_vm[*].id

  named_port {
    name = "http"
    port = 80
  }

  lifecycle {
    create_before_destroy = true
  }
}
