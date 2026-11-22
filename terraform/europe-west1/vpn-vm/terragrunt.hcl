terraform {
  source = "${get_terragrunt_dir()}/../../../terraform-library//modules/gce-vm/v1.1.0"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  region        = yamldecode(file(find_in_parent_folders("region.yaml")))
  common_locals = yamldecode(file(find_in_parent_folders("common_locals.yaml")))
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    network_name = "fleetdm-vpc"
    subnet_name  = "fleetdm-europe-west1"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependencies {
  paths = ["../firewall"]
}

inputs = {
  name             = "vpn-vm"
  region           = local.region.name
  zone             = local.region.zone
  network          = dependency.vpc.outputs.network_name
  subnetwork       = dependency.vpc.outputs.subnet_name
  machine_type     = "e2-micro"
  boot_image       = "debian-cloud/debian-13"
  external_ip_type = "static"
  labels           = merge(local.common_locals.labels, { component = "vpn" })

  create_instance_group   = false
  create_lb_firewall_rule = false

  metadata = {
    enable-guest-attributes = "TRUE"
  }

  startup_script = templatefile("${get_terragrunt_dir()}/../scripts/openvpn-server.sh.tftpl", {
    vpn_port           = 1194
    vpn_client_cidr    = local.region.vpn_client_cidr
    vpn_client_network = cidrhost(local.region.vpn_client_cidr, 0)
    vpn_client_netmask = cidrnetmask(local.region.vpn_client_cidr)
    subnet_network     = cidrhost(local.region.subnet_cidr, 0)
    subnet_netmask     = cidrnetmask(local.region.subnet_cidr)
    dns_domain         = local.common_locals.dns_domain
    client_name        = "fleet-admin"
  })
}
