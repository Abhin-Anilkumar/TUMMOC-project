# ============================================
# Craftista - Compute Engine VMs
# ============================================

# ─────────────────────────────────────────
# Startup Script (installs Docker & Docker Compose)
# ─────────────────────────────────────────
locals {
  startup_script = <<-SCRIPT
    #!/bin/bash
    set -e

    # Update system
    apt-get update -y
    apt-get upgrade -y

    # Install required packages
    apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      software-properties-common \
      git \
      jq

    # ── Install Docker ────────────────────
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start Docker
    systemctl enable docker
    systemctl start docker

    # Add user to docker group
    usermod -aG docker ${var.ssh_user} || true

    # ── Install Docker Compose (standalone) ──
    DOCKER_COMPOSE_VERSION="v2.24.0"
    curl -SL "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # ── Install Google Cloud SDK ──────────
    # (Already available on GCE Ubuntu images)

    # ── Create application directory ──────
    mkdir -p /opt/craftista
    chown -R ${var.ssh_user}:${var.ssh_user} /opt/craftista

    # ── Install Node Exporter (for Prometheus monitoring) ──
    NODE_EXPORTER_VERSION="1.7.0"
    wget -q "https://github.com/prometheus/node_exporter/releases/download/v$${NODE_EXPORTER_VERSION}/node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
    tar xzf "node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
    mv "node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
    rm -rf "node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64"*

    # Create systemd service for Node Exporter
    cat > /etc/systemd/system/node_exporter.service <<EOF
    [Unit]
    Description=Node Exporter
    Wants=network-online.target
    After=network-online.target

    [Service]
    User=nobody
    ExecStart=/usr/local/bin/node_exporter
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    EOF

    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter

    echo "===== Startup script completed successfully ====="
  SCRIPT
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
    instance = "vm-${count.index + 1}"
    environment = var.environment
  })

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.craftista_subnet.id

    # Assign external IP for direct access (remove for production with LB only)
    access_config {
      // Ephemeral public IP
    }
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
