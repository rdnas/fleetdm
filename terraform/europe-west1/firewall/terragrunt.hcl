terraform {
  source = "${get_terragrunt_dir()}/../../../terraform-library//modules/firewall/v1.0.0"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  region = yamldecode(file(find_in_parent_folders("region.yaml")))
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    network_name = "fleetdm-vpc"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Firewall logging is never enabled. Everything not allowed here is dropped by GCP's implicit deny-all ingress.
inputs = {
  network = dependency.vpc.outputs.network_name

  rules = {
    # The only externally reachable port/protocol: no external SSH, ICMP or IAP.
    fleetdm-allow-openvpn = {
      description   = "OpenVPN from admin IPs to the VPN VM"
      source_ranges = local.region.admin_cidrs
      target_tags   = ["vpn-vm"]
      allow         = [{ protocol = "udp", ports = ["1194"] }]
    }

    fleetdm-allow-internal = {
      description   = "All traffic from the subnet and from NATed VPN clients"
      source_ranges = [local.region.subnet_cidr, local.region.vpn_client_cidr]
      allow         = [{ protocol = "all" }]
    }

    fleetdm-allow-gcp-healthchecks = {
      description   = "Google health-check probers (kept for a future load balancer)"
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
      allow         = [{ protocol = "tcp" }]
    }
  }
}
