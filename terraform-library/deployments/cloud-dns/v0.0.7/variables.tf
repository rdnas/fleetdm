variable "terraform_state_bucket_name" {}
variable "environment" {}
variable "region" {}
variable "host_project_id" {}
variable "service_project_id" {}

variable "zone" {
  description = "The GCP zone to create resources in"
  type        = string
  default     = null
}

variable "cloud_zones" {
  type = map(object({
    name                               = string
    type                               = string
    domain                             = string
    private_visibility_config_networks = list(string) # this  will contain lists of networks which will be peered
    recordsets = list(object({
      name    = string
      type    = string
      ttl     = number
      records = optional(list(string), null)
      routing_policy = optional(object({
        wrr = optional(list(object({
          weight  = number
          records = list(string)
        })), [])
        geo = optional(list(object({
          location = string
          records  = list(string)
        })), [])
      }))
    }))

    target_name_server_addresses = optional(list(map(any)))
    target_network               = optional(string)
    labels                       = map(string)
  }))
}
