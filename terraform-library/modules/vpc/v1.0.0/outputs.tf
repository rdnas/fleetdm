output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "The self_link of the VPC network"
  value       = google_compute_network.this.self_link
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.this.name
}

output "subnet_self_link" {
  description = "The self_link of the subnet"
  value       = google_compute_subnetwork.this.self_link
}

output "subnet_cidr" {
  description = "The primary IPv4 range of the subnet"
  value       = google_compute_subnetwork.this.ip_cidr_range
}

output "router_name" {
  description = "The name of the Cloud Router, or null if create_nat is false"
  value       = try(google_compute_router.this[0].name, null)
}

output "nat_name" {
  description = "The name of the Cloud NAT, or null if create_nat is false"
  value       = try(google_compute_router_nat.this[0].name, null)
}
