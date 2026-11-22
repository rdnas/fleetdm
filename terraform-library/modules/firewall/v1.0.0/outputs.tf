output "rule_names" {
  description = "Names of the firewall rules"
  value       = keys(google_compute_firewall.this)
}

output "rule_self_links" {
  description = "Self links of the firewall rules, keyed by name"
  value       = { for k, r in google_compute_firewall.this : k => r.self_link }
}
