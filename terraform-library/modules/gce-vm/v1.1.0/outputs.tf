output "name" {
  description = "The name of the VM"
  value       = google_compute_instance.this.name
}

output "self_link" {
  description = "The self_link of the VM"
  value       = google_compute_instance.this.self_link
}

output "internal_ip" {
  description = "The internal IP of the VM"
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "external_ip" {
  description = "The external IP of the VM (static or ephemeral), or null if it has none"
  value       = try(google_compute_instance.this.network_interface[0].access_config[0].nat_ip, null)
}

output "instance_group_self_link" {
  description = "The self_link of the unmanaged instance group containing the VM, or null if create_instance_group is false"
  value       = try(google_compute_instance_group.this[0].self_link, null)
}
