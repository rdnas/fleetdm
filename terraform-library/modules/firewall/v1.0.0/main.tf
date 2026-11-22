resource "google_compute_firewall" "this" {
  for_each = var.rules

  name        = each.key
  network     = var.network
  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority

  source_ranges      = each.value.source_ranges
  destination_ranges = each.value.destination_ranges
  source_tags        = each.value.source_tags
  target_tags        = each.value.target_tags

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}
