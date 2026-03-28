#!/bin/bash
# ============================================
# Craftista - Docker & Dependencies Install Script
# Run on GCP VM (Ubuntu 22.04)
# ============================================
set -e

echo "===== Starting Craftista VM Setup ====="

# ── Update system ─────────────────────────
echo "[1/7] Updating system packages..."
apt-get update -y
apt-get upgrade -y

# ── Install prerequisites ─────────────────
echo "[2/7] Installing prerequisites..."
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  git \
  jq \
  wget

# ── Install Docker ────────────────────────
echo "[3/7] Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start & enable Docker
systemctl enable docker
systemctl start docker

# ── Install Docker Compose (standalone) ───
echo "[4/7] Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="v2.24.0"
curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# ── Format & mount data disk ─────────────
echo "[5/7] Setting up data disk..."
DATA_DISK="/dev/sdb"
MOUNT_POINT="/opt/craftista"

if [ -b "$DATA_DISK" ]; then
  # Check if already formatted
  if ! blkid "$DATA_DISK" | grep -q ext4; then
    echo "Formatting data disk..."
    mkfs.ext4 -F "$DATA_DISK"
  fi

  mkdir -p "$MOUNT_POINT"
  mount "$DATA_DISK" "$MOUNT_POINT"

  # Add to fstab for persistence
  if ! grep -q "$MOUNT_POINT" /etc/fstab; then
    echo "$DATA_DISK $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
else
  echo "No data disk found at $DATA_DISK, creating directory..."
  mkdir -p "$MOUNT_POINT"
fi

# Move Docker data directory to data disk (more space)
mkdir -p "$MOUNT_POINT/docker-data"
if [ ! -f /etc/docker/daemon.json ]; then
  cat > /etc/docker/daemon.json <<EOF
{
  "data-root": "$MOUNT_POINT/docker-data"
}
EOF
  systemctl restart docker
fi

# ── Install Node Exporter ────────────────
echo "[6/7] Installing Node Exporter..."
NODE_EXPORTER_VERSION="1.7.0"
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
mv "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
rm -rf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"*

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

# ── Configure Docker auth for Artifact Registry ──
echo "[7/7] Configuring GCP Artifact Registry access..."
gcloud auth configure-docker asia-south1-docker.pkg.dev --quiet 2>/dev/null || true

# ── Print status ──────────────────────────
echo ""
echo "===== Setup Complete ====="
echo "Docker version:  $(docker --version)"
echo "Compose version: $(docker-compose --version)"
echo "Data disk mount: $(df -h $MOUNT_POINT | tail -1)"
echo "=========================="
