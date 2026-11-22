terraform {
  source = "${get_terragrunt_dir()}/../../../terraform-library//deployments/cloud-dns/v0.0.7"
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
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "vpn_vm" {
  config_path = "../vpn-vm"
  mock_outputs = {
    internal_ip = "10.10.0.2"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "minikube_vm" {
  config_path = "../minikube-vm"
  mock_outputs = {
    internal_ip = "10.10.0.3"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "agent_vm" {
  config_path = "../agent-vm"
  mock_outputs = {
    internal_ip = "10.10.0.4"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  terraform_state_bucket_name = local.common_locals.state_bucket
  environment                 = "fleetdm"
  region                      = local.region.name
  host_project_id             = local.common_locals.project_id
  service_project_id          = local.common_locals.project_id

  cloud_zones = {
    "${local.common_locals.dns_domain}" = {
      name                               = "fleetdm-private"
      type                               = "private"
      domain                             = "${local.common_locals.dns_domain}."
      labels                             = local.common_locals.labels
      private_visibility_config_networks = ["projects/${local.common_locals.project_id}/global/networks/${dependency.vpc.outputs.network_name}"]
      recordsets = [
        {
          name    = "fleet"
          type    = "A"
          ttl     = 300
          records = [dependency.minikube_vm.outputs.internal_ip]
        },
        {
          name    = "minikube-vm"
          type    = "A"
          ttl     = 300
          records = [dependency.minikube_vm.outputs.internal_ip]
        },
        {
          name    = "agent-vm"
          type    = "A"
          ttl     = 300
          records = [dependency.agent_vm.outputs.internal_ip]
        },
        {
          name    = "vpn-vm"
          type    = "A"
          ttl     = 300
          records = [dependency.vpn_vm.outputs.internal_ip]
        },
      ]
    }
  }
}
