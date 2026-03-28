# 🚀 Craftista DevOps Pipeline - TUMMOC

[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](/.github/workflows/ci-cd.yml)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](docker-compose.yml)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](terraform/)
[![GCP](https://img.shields.io/badge/Cloud-GCP-4285F4?logo=google-cloud)](terraform/)
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%2B%20Grafana-E6522C?logo=prometheus)](monitoring/)

A complete DevOps pipeline for the **Craftista** microservices application, deployed on **GCP VMs** with **Nginx Load Balancer**, **GitHub Actions CI/CD**, and **Prometheus/Grafana** monitoring.

---

## 📐 Architecture

```
                            ┌──────────────────────┐
                            │   GitHub Actions      │
                            │   CI/CD Pipeline      │
                            │  (Lint→Test→Build→    │
                            │   Push→Deploy)        │
                            └─────────┬────────────┘
                                      │
                                      ▼
                        ┌─────────────────────────────┐
                        │    GCP HTTP Load Balancer    │
                        │     (Global Forwarding)      │
                        └──────────┬──────────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    ▼                             ▼
          ┌─────────────────┐           ┌─────────────────┐
          │  VM-1 (Nginx)   │           │  VM-2 (Nginx)   │
          │  ┌───────────┐  │           │  ┌───────────┐  │
          │  │ Frontend   │  │           │  │ Frontend   │  │
          │  │ :3000      │  │           │  │ :3000      │  │
          │  ├───────────┤  │           │  ├───────────┤  │
          │  │ Catalogue  │  │           │  │ Catalogue  │  │
          │  │ :5000      │  │           │  │ :5000      │  │
          │  ├───────────┤  │           │  ├───────────┤  │
          │  │ Voting     │  │           │  │ Voting     │  │
          │  │ :8080      │  │           │  │ :8080      │  │
          │  ├───────────┤  │           │  ├───────────┤  │
          │  │ Recommend  │  │           │  │ Recommend  │  │
          │  │ :8080      │  │           │  │ :8080      │  │
          │  └───────────┘  │           │  └───────────┘  │
          └─────────────────┘           └─────────────────┘
                    │                             │
                    └──────────┬──────────────────┘
                               ▼
                    ┌─────────────────────┐
                    │  Prometheus + Grafana │
                    │  (Monitoring Stack)   │
                    └─────────────────────┘
```

---

## 📋 Project Structure

```
TUMMOC/
├── PREREQUISITES.md                    # ⚙️ Setup requirements & guide
├── README.md                           # 📖 This file
├── docker-compose.yml                  # 🐳 Local development / VM deployment
│
├── app/                                # 📦 Application source code
│   ├── frontend/                       # Node.js (Express) - Port 3000
│   ├── catalogue/                      # Python (Flask) - Port 5000
│   ├── voting/                         # Java (Spring Boot) - Port 8080
│   └── recommendation/                 # Go (Gin) - Port 8080
│
├── nginx/                              # 🔀 Reverse proxy configuration
│   ├── nginx.conf
│   └── Dockerfile
│
├── .github/workflows/                  # 🔄 CI/CD pipeline
│   └── ci-cd.yml
│
├── terraform/                          # 🏗️ GCP Infrastructure as Code
│   ├── main.tf                         # Provider config
│   ├── variables.tf                    # Input variables
│   ├── vpc.tf                          # VPC, subnets, firewall
│   ├── compute.tf                      # VM instances
│   ├── loadbalancer.tf                 # HTTP Load Balancer
│   ├── storage.tf                      # GCS & Artifact Registry
│   ├── outputs.tf                      # Output values
│   └── terraform.tfvars.example        # Example variables
│
└── monitoring/                         # 📊 Monitoring stack
    ├── docker-compose.monitoring.yml   # Prometheus + Grafana
    ├── prometheus/prometheus.yml        # Scrape configuration
    └── grafana/
        ├── dashboards/                 # Pre-built dashboards
        └── provisioning/               # Auto-config
```

---

## 🚀 Quick Start

### Prerequisites
See [PREREQUISITES.md](PREREQUISITES.md) for detailed requirements.

### 1. Local Development (Docker Compose)

```bash
cd TUMMOC

# Build and start all services
docker-compose up -d --build

# Verify services are running
docker-compose ps

# Access the application
open http://localhost    # Via Nginx reverse proxy

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### 2. Deploy to GCP

```bash
# Step 1: Configure Terraform
cd TUMMOC/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GCP project details

# Step 2: Initialize and apply Terraform
terraform init
terraform plan
terraform apply

# Step 3: Note the output IPs
# load_balancer_ip = "x.x.x.x"
# vm_external_ips  = ["x.x.x.x", "y.y.y.y"]

# Step 4: Deploy application to VMs
gcloud compute ssh craftista-vm-1 --zone=asia-south1-a --command="
  cd /opt/craftista
  # Copy docker-compose.yml and nginx/ to this directory
  docker-compose up -d
"

# Step 5: Access via Load Balancer
curl http://<LOAD_BALANCER_IP>/health
```

### 3. Start Monitoring

```bash
cd TUMMOC/monitoring

# Start monitoring stack (requires app network to exist)
docker-compose -f docker-compose.monitoring.yml up -d

# Access dashboards
open http://localhost:9090    # Prometheus
open http://localhost:3001    # Grafana (admin / craftista123)
```

---

## 🔄 CI/CD Pipeline

The GitHub Actions pipeline runs on every push and PR:

| Stage | Trigger | What It Does |
|-------|---------|-------------|
| **🔍 Lint** | PR / Push | ESLint, flake8, go vet |
| **🧪 Test** | PR / Push | npm test, pytest |
| **🏗️ Build** | PR / Push | Docker build all 5 images |
| **📦 Push** | Push to main/develop | Push to Google Artifact Registry |
| **🚀 Deploy** | Push to main | SSH to VM, pull images, restart |

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `WIF_PROVIDER` | Workload Identity Federation Provider string |
| `WIF_SERVICE_ACCOUNT` | The service account email used for CI/CD |

---

## 🏗️ Terraform Resources

| Resource | Type | Details |
|----------|------|---------|
| VPC Network | `google_compute_network` | Custom VPC |
| Subnet | `google_compute_subnetwork` | 10.0.1.0/24 |
| Firewall Rules | `google_compute_firewall` | SSH, HTTP, HTTPS, Health Checks |
| VM Instances (×2) | `google_compute_instance` | e2-medium, Ubuntu 22.04 |
| Instance Group | `google_compute_instance_group` | For LB backend |
| Health Check | `google_compute_health_check` | HTTP /health |
| Backend Service | `google_compute_backend_service` | Load balancer backend |
| URL Map | `google_compute_url_map` | Routing rules |
| HTTP Proxy | `google_compute_target_http_proxy` | HTTP proxy |
| Forwarding Rule | `google_compute_global_forwarding_rule` | Entry point |
| Cloud NAT | `google_compute_router_nat` | Outbound internet |
| GCS Buckets | `google_storage_bucket` | State + assets |
| Artifact Registry | `google_artifact_registry_repository` | Docker images |

```bash
# Common Terraform commands
terraform init      # Initialize
terraform plan      # Preview changes
terraform apply     # Apply changes
terraform destroy   # Tear down everything
terraform output    # View outputs
```

---

## 📊 Monitoring

### Stack Components

| Component | Port | Purpose |
|-----------|------|---------|
| **Prometheus** | 9090 | Metrics collection & storage |
| **Grafana** | 3001 | Dashboard visualization |
| **Node Exporter** | 9100 | Host-level metrics |

### Grafana Dashboard Panels

- **CPU Usage** — Gauge (green/yellow/red thresholds)
- **Memory Usage** — Gauge with percentage
- **Disk Usage** — Gauge with percentage
- **Service Health** — UP/DOWN status for all 4 services
- **Network Traffic** — Time series for received/transmitted bytes

### Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| Grafana | `admin` | `craftista123` |

---

## 🛠️ Microservices

| Service | Language | Framework | Port | Description |
|---------|----------|-----------|------|-------------|
| **Frontend** | Node.js | Express | 3000 | Main UI, proxies to backends |
| **Catalogue** | Python | Flask | 5000 | Product catalog API |
| **Voting** | Java | Spring Boot | 8080 | Voting system |
| **Recommendation** | Go | Gin | 8080 | Daily origami recommendation |

---

## 👤 Author

**Abhin Anilkumar**
- GitHub: [@Abhin-Anilkumar](https://github.com/Abhin-Anilkumar)
