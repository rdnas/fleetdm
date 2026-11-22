resource "google_compute_network" "this" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "this" {
  name                     = var.subnet_name
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

resource "google_compute_router" "this" {
  count   = var.create_nat ? 1 : 0
  name    = coalesce(var.router_name, "${var.network_name}-router")
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  count                              = var.create_nat ? 1 : 0
  name                               = coalesce(var.nat_name, "${var.network_name}-nat")
  region                             = var.region
  router                             = google_compute_router.this[0].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = false
    filter = "ALL"
  }
}
