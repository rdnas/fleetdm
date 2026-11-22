variable "credentials" {
  description = "Either the path to or the contents of a service account key file in JSON format."
  default     = ""
}

variable "project_id" {
  type        = string
  description = "The ID of the project where the network will be created"
}

variable "region" {
  type        = string
  description = "The region of the subnet, Cloud Router and Cloud NAT"
}

variable "network_name" {
  type        = string
  description = "Name of the custom-mode VPC network"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
}

variable "subnet_cidr" {
  type        = string
  description = "Primary IPv4 range of the subnet"
}

variable "routing_mode" {
  type        = string
  description = "Network routing mode (REGIONAL or GLOBAL)"
  default     = "REGIONAL"
}

variable "create_nat" {
  type        = bool
  description = "Whether to create a Cloud Router and Cloud NAT for egress from VMs without external IPs"
  default     = true
}

variable "router_name" {
  type        = string
  description = "Name of the Cloud Router. Defaults to <network_name>-router."
  default     = null
}

variable "nat_name" {
  type        = string
  description = "Name of the Cloud NAT. Defaults to <network_name>-nat."
  default     = null
}
