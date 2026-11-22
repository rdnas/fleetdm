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

# fleetd is installed from the .deb built on minikube-vm (make agent-package); names resolve via Cloud DNS.
inputs = {
  name             = "agent-vm"
  region           = local.region.name
  zone             = local.region.zone
  network          = dependency.vpc.outputs.network_name
  subnetwork       = dependency.vpc.outputs.subnet_name
  machine_type     = "e2-micro"
  boot_image       = "debian-cloud/debian-13"
  external_ip_type = "none"
  labels           = merge(local.common_locals.labels, { component = "fleet-agent" })

  create_instance_group   = false
  create_lb_firewall_rule = false
}
