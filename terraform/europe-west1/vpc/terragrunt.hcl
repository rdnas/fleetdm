terraform {
  source = "${get_terragrunt_dir()}/../../../terraform-library//modules/vpc/v1.0.0"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  region = yamldecode(file(find_in_parent_folders("region.yaml")))
}

inputs = {
  region       = local.region.name
  network_name = local.region.network
  subnet_name  = local.region.subnetwork
  subnet_cidr  = local.region.subnet_cidr
  router_name  = "fleetdm-router"
  nat_name     = "fleetdm-nat"
}
