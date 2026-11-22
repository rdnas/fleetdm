module "cloud-zone" {
  source   = "../../../modules/terraform-google-cloud-dns/v7.2.1/"
  for_each = var.cloud_zones

  project_id = var.host_project_id
  type       = each.value.type
  name       = each.value.name
  domain     = each.value.domain
  labels = merge({
    name = each.value.name
  }, each.value.labels)

  private_visibility_config_networks = each.value.private_visibility_config_networks
  recordsets                         = each.value.recordsets

  target_name_server_addresses = each.value.target_name_server_addresses
  target_network               = each.value.target_network
}
