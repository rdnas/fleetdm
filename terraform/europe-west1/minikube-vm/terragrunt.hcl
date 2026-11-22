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

# No external IP: egress goes through Cloud NAT; admins reach it over the VPN.
inputs = {
  name              = "minikube-vm"
  region            = local.region.name
  zone              = local.region.zone
  network           = dependency.vpc.outputs.network_name
  subnetwork        = dependency.vpc.outputs.subnet_name
  machine_type      = "n2-standard-2"
  boot_image        = "ubuntu-os-cloud/ubuntu-2604-lts-amd64"
  boot_disk_size_gb = 50
  boot_disk_type    = "pd-balanced"
  external_ip_type  = "none"
  labels            = merge(local.common_locals.labels, { component = "minikube" })

  create_instance_group   = false
  create_lb_firewall_rule = false

  startup_script = templatefile("${get_terragrunt_dir()}/../scripts/minikube-host.sh.tftpl", {
    minikube_version = "v1.39.0"
    kubectl_version  = "v1.37.2"
    helm_version     = "v4.3.2"
    fleetctl_version = "4.95.0"
  })
}
