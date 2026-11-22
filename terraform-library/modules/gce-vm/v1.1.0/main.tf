locals {
  default_sa_scopes = [
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
  ]

  external_ip_type = coalesce(var.external_ip_type, var.assign_external_ip ? "ephemeral" : "none")
}

resource "google_compute_address" "this" {
  count        = local.external_ip_type == "static" ? 1 : 0
  name         = "${var.name}-ip"
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
  labels       = var.labels
}

resource "google_compute_instance" "this" {
  name                      = var.name
  zone                      = var.zone
  machine_type              = var.machine_type
  tags                      = distinct(concat([var.name], var.network_tags))
  labels                    = var.labels
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    dynamic "access_config" {
      for_each = local.external_ip_type == "none" ? [] : [1]
      content {
        nat_ip = local.external_ip_type == "static" ? google_compute_address.this[0].address : null
      }
    }
  }

  # metadata_startup_script would force replacement on change; metadata["startup-script"] updates in place.
  metadata = merge(
    { enable-oslogin = "TRUE" },
    var.startup_script != "" ? { startup-script = var.startup_script } : {},
    var.metadata,
  )

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_email == null ? local.default_sa_scopes : ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

resource "google_compute_instance_group" "this" {
  count     = var.create_instance_group ? 1 : 0
  name      = "${var.name}-ig"
  zone      = var.zone
  network   = google_compute_instance.this.network_interface[0].network
  instances = [google_compute_instance.this.self_link]

  named_port {
    name = var.named_port_name
    port = var.named_port
  }
}

resource "google_compute_firewall" "allow_lb" {
  count   = var.create_lb_firewall_rule ? 1 : 0
  name    = "${var.name}-allow-lb"
  network = var.network

  direction     = "INGRESS"
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = [var.name]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.named_port)]
  }
}
