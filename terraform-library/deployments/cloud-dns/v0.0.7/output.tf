output "zone_names" {
  description = "Managed zone names, keyed by the cloud_zones map key"
  value       = { for k, z in module.cloud-zone : k => z.name }
}

output "zone_domains" {
  description = "Managed zone DNS names, keyed by the cloud_zones map key"
  value       = { for k, z in module.cloud-zone : k => z.domain }
}
