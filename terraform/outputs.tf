# ============================================
# Craftista - Terraform Outputs
# ============================================

# ─────────────────────────────────────────
# Load Balancer
# ─────────────────────────────────────────
output "load_balancer_ip" {
  description = "The external IP address of the HTTP(S) load balancer"
  value       = google_compute_global_forwarding_rule.craftista_forwarding_rule.ip_address
}

output "static_ip" {
  description = "The reserved static IP address"
  value       = google_compute_global_address.craftista_ip.address
}

output "application_url" {
  description = "URL to access the application via load balancer"
  value       = "http://${google_compute_global_forwarding_rule.craftista_forwarding_rule.ip_address}"
}

# ─────────────────────────────────────────
# VM Instances
# ─────────────────────────────────────────
output "vm_names" {
  description = "Names of the created VM instances"
  value       = google_compute_instance.craftista_vm[*].name
}

output "vm_internal_ips" {
  description = "Internal IP addresses of VM instances (no public IPs)"
  value       = google_compute_instance.craftista_vm[*].network_interface[0].network_ip
}

# ─────────────────────────────────────────
# Network
# ─────────────────────────────────────────
output "vpc_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.craftista_vpc.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.craftista_subnet.name
}

output "subnet_cidr" {
  description = "CIDR range of the subnet"
  value       = google_compute_subnetwork.craftista_subnet.ip_cidr_range
}

# ─────────────────────────────────────────
# Storage
# ─────────────────────────────────────────
output "terraform_state_bucket" {
  description = "GCS bucket for Terraform state"
  value       = google_storage_bucket.terraform_state.name
}

output "artifact_registry_url" {
  description = "URL of the Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.craftista_repo.repository_id}"
}

# ─────────────────────────────────────────
# SSH Connection (via IAP tunnel - no public IP)
# ─────────────────────────────────────────
output "ssh_commands" {
  description = "SSH commands to connect via IAP tunnel (no public IP needed)"
  value = [
    for i, vm in google_compute_instance.craftista_vm :
    "gcloud compute ssh ${vm.name} --zone=${var.zone} --project=${var.project_id} --tunnel-through-iap"
  ]
}
