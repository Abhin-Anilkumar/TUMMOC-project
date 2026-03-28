# ============================================
# Craftista - HTTP(S) Load Balancer
# ============================================

# ─────────────────────────────────────────
# Health Check
# ─────────────────────────────────────────
resource "google_compute_health_check" "craftista_health_check" {
  name                = "craftista-health-check"
  description         = "Health check for Craftista application"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/health"
  }
}

# ─────────────────────────────────────────
# Backend Service
# ─────────────────────────────────────────
resource "google_compute_backend_service" "craftista_backend" {
  name                  = "craftista-backend-service"
  description           = "Backend service for Craftista application"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_health_check.craftista_health_check.id]

  backend {
    group           = google_compute_instance_group.craftista_group.id
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  # Session affinity (optional)
  session_affinity = "NONE"

  # Logging
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# ─────────────────────────────────────────
# URL Map (routing rules)
# ─────────────────────────────────────────
resource "google_compute_url_map" "craftista_url_map" {
  name            = "craftista-url-map"
  description     = "URL map for Craftista application"
  default_service = google_compute_backend_service.craftista_backend.id
}

# ─────────────────────────────────────────
# Target HTTP Proxy
# ─────────────────────────────────────────
resource "google_compute_target_http_proxy" "craftista_http_proxy" {
  name    = "craftista-http-proxy"
  url_map = google_compute_url_map.craftista_url_map.id
}

# ─────────────────────────────────────────
# Global Forwarding Rule (Entry Point)
# ─────────────────────────────────────────
resource "google_compute_global_forwarding_rule" "craftista_forwarding_rule" {
  name                  = "craftista-forwarding-rule"
  target                = google_compute_target_http_proxy.craftista_http_proxy.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.craftista_ip.id
}

# ─────────────────────────────────────────
# Static IP Address (Optional - for DNS)
# ─────────────────────────────────────────
resource "google_compute_global_address" "craftista_ip" {
  name        = "craftista-global-ip"
  description = "Static IP for Craftista load balancer"
}
