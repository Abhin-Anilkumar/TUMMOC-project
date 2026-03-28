# 📋 Prerequisites - Craftista DevOps Pipeline

This document lists everything you need before deploying the Craftista application using this DevOps pipeline.

---

## 🖥️ Local Development Tools

| Tool | Version | Purpose | Install Command |
|------|---------|---------|-----------------|
| **Docker** | >= 24.0 | Container runtime | [Install Docker](https://docs.docker.com/get-docker/) |
| **Docker Compose** | >= 2.20 | Multi-container orchestration | Included with Docker Desktop |
| **Terraform** | >= 1.5.0 | Infrastructure as Code | `brew install terraform` |
| **Google Cloud SDK** | >= 450.0 | GCP CLI tools | `brew install google-cloud-sdk` |
| **Git** | >= 2.40 | Version control | `brew install git` |
| **kubectl** | >= 1.28 | Kubernetes CLI (optional) | `brew install kubectl` |
| **Node.js** | >= 21.0 | Frontend development | `brew install node` |
| **Python** | >= 3.11 | Catalogue development | `brew install python@3.11` |
| **Go** | >= 1.20 | Recommendation development | `brew install go` |
| **Java JDK** | >= 17 | Voting development | `brew install openjdk@17` |
| **Maven** | >= 3.9 | Java build tool | `brew install maven` |

### Quick Install (macOS with Homebrew)

```bash
# Install all required tools
brew install docker terraform google-cloud-sdk git kubectl node python@3.11 go openjdk@17 maven

# Verify installations
docker --version
docker-compose --version
terraform --version
gcloud --version
git --version
node --version
python3 --version
go version
java --version
mvn --version
```

---

## ☁️ GCP (Google Cloud Platform) Setup

### 1. GCP Account & Project

- [ ] **GCP Account**: Create at [console.cloud.google.com](https://console.cloud.google.com)
- [ ] **Billing Account**: Enable billing on your GCP project
- [ ] **GCP Project**: Create a new project or use an existing one

```bash
# Create a new project
gcloud projects create YOUR_PROJECT_ID --name="Craftista DevOps"

# Set it as default
gcloud config set project YOUR_PROJECT_ID
```

### 2. Enable Required APIs

```bash
# Enable all required GCP APIs
gcloud services enable \
  compute.googleapis.com \
  artifactregistry.googleapis.com \
  cloudresourcemanager.googleapis.com \
  storage.googleapis.com \
  iam.googleapis.com \
  iap.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com
```

### 3. Service Account

```bash
# Create service account for Terraform & CI/CD
gcloud iam service-accounts create craftista-devops \
  --display-name="Craftista DevOps Service Account" \
  --description="Service account for Terraform and CI/CD pipeline"

# Grant required roles
PROJECT_ID=$(gcloud config get-value project)

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:craftista-devops@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:craftista-devops@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:craftista-devops@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:craftista-devops@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Download credentials key
gcloud iam service-accounts keys create credentials.json \
  --iam-account=craftista-devops@${PROJECT_ID}.iam.gserviceaccount.com

# Move key to terraform directory
mv credentials.json TUMMOC/terraform/
```

### 4. SSH Key Pair

```bash
# Generate SSH key pair (if you don't have one)
ssh-keygen -t rsa -b 4096 -C "craftista@devops" -f ~/.ssh/craftista_rsa -N ""

# Update terraform.tfvars with the key path
# ssh_pub_key_file = "~/.ssh/craftista_rsa.pub"
```

---

## 🔧 GitHub Setup

### 1. Repository Secrets

Navigate to your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `GCP_SA_KEY` | Contents of `credentials.json` | GCP service account key (JSON) |
| `GCP_PROJECT_ID` | `your-gcp-project-id` | GCP project ID |

### 2. GitHub Environments (Optional)

For production deployment approval:

1. Go to **Settings** → **Environments**
2. Create `production` environment
3. Add **required reviewers** for manual approval
4. Add **deployment branches** → `main` only

### 3. Branch Protection Rules (Recommended)

For `main` branch:
- [x] Require pull request reviews
- [x] Require status checks to pass before merging
- [x] Require branches to be up to date

---

## 📁 Terraform Configuration

### 1. Create `terraform.tfvars`

```bash
cd TUMMOC/terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit Variables

```hcl
# terraform.tfvars
project_id       = "your-actual-gcp-project-id"
credentials_file = "credentials.json"
region           = "asia-south1"
zone             = "asia-south1-a"
machine_type     = "e2-medium"
vm_count         = 2
ssh_user         = "craftista"
ssh_pub_key_file = "~/.ssh/craftista_rsa.pub"
```

### 3. Initialize Terraform

```bash
cd TUMMOC/terraform
terraform init
terraform plan
```

---

## ✅ Pre-Flight Checklist

Before deploying, verify everything is in place:

```
Local Tools:
  □ Docker is installed and running
  □ Docker Compose is available
  □ Terraform >= 1.5.0 is installed
  □ gcloud CLI is installed and authenticated
  □ Git is installed

GCP:
  □ GCP project is created
  □ Billing is enabled
  □ Required APIs are enabled
  □ Service account is created with correct roles
  □ credentials.json is downloaded and placed in terraform/
  □ SSH key pair is generated

GitHub:
  □ Repository is created
  □ GCP_SA_KEY secret is configured
  □ GCP_PROJECT_ID secret is configured
  □ Production environment is set up (optional)

Terraform:
  □ terraform.tfvars is created from example
  □ Variables are filled with actual values
  □ terraform init succeeds
  □ terraform plan shows expected resources
```

---

## 💰 Estimated GCP Costs

| Resource | Specification | Monthly Cost (Approx.) |
|----------|---------------|----------------------|
| 2× Compute Engine (e2-medium) | 2 vCPU, 4GB RAM each | ~$50/month |
| Load Balancer | HTTP forwarding rule | ~$18/month |
| Cloud NAT | For outbound access | ~$5/month |
| GCS Storage | Terraform state + assets | ~$1/month |
| Artifact Registry | Docker images | ~$2/month |
| Network Egress | Depends on traffic | Variable |
| **Total Estimate** | | **~$76/month** |

> **💡 Tip**: Use `e2-micro` (free tier eligible) for testing to reduce costs. Update `machine_type` in `terraform.tfvars`.

---

## 🆘 Troubleshooting

### Docker Issues
```bash
# Check Docker is running
docker info

# Reset Docker (macOS)
# Open Docker Desktop → Troubleshoot → Reset to factory defaults
```

### GCP Authentication
```bash
# Re-authenticate gcloud
gcloud auth login
gcloud auth application-default login

# Verify project
gcloud config list
```

### Terraform Issues
```bash
# Clean state and reinitialize
rm -rf .terraform .terraform.lock.hcl
terraform init

# Enable debug logging
export TF_LOG=DEBUG
terraform plan
```
