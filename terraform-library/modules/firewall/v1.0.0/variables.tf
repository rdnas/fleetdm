variable "credentials" {
  description = "Either the path to or the contents of a service account key file in JSON format."
  default     = ""
}

variable "project_id" {
  type        = string
  description = "The ID of the project that owns the network"
}

variable "network" {
  type        = string
  description = "Name or self_link of the VPC network the rules apply to"
}

variable "rules" {
  description = "Firewall rules keyed by rule name. Firewall rule logging is never enabled."
  type = map(object({
    description        = optional(string)
    direction          = optional(string, "INGRESS")
    priority           = optional(number, 1000)
    source_ranges      = optional(list(string))
    destination_ranges = optional(list(string))
    source_tags        = optional(list(string))
    target_tags        = optional(list(string))
    allow = list(object({
      protocol = string
      ports    = optional(list(string), [])
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.rules) : contains(["INGRESS", "EGRESS"], r.direction)])
    error_message = "direction must be INGRESS or EGRESS."
  }
}
