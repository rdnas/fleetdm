variable "credentials" {
  description = "Either the path to or the contents of a service account key file in JSON format."
  default     = ""
}

variable "project_id" {
  type        = string
  description = "The ID of the project where the VM will be created"
}

variable "region" {
  type        = string
  description = "The region where the VM (and its static external IP, if any) will be created"
}

variable "zone" {
  type        = string
  description = "The zone where the VM and its instance group will be created"
}

variable "name" {
  type        = string
  description = "Name of the VM. Also used as its network tag and as the prefix for the instance group, firewall rule and static IP."
}

variable "network" {
  type        = string
  description = "Name or self_link of the VPC network"
}

variable "subnetwork" {
  type        = string
  description = "Name or self_link of the subnetwork"
}

variable "network_tags" {
  type        = list(string)
  description = "Extra network tags added to the VM (the VM's own name is always added)"
  default     = []
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the VM (and its static external IP, if any)"
  default     = {}
}

variable "startup_script" {
  type        = string
  description = "Startup script stored in metadata[\"startup-script\"]"
  default     = ""
}

variable "metadata" {
  type        = map(string)
  description = "Extra instance metadata, merged on top of enable-oslogin and startup-script"
  default     = {}
}

variable "machine_type" {
  type        = string
  description = "Machine type of the VM"
  default     = "e2-small"
}

variable "boot_image" {
  type        = string
  description = "Boot disk image"
  default     = "debian-cloud/debian-12"
}

variable "boot_disk_size_gb" {
  type        = number
  description = "Boot disk size in GB"
  default     = 10
}

variable "boot_disk_type" {
  type        = string
  description = "Boot disk type (pd-standard, pd-balanced, pd-ssd, ...)"
  default     = "pd-balanced"
}

variable "external_ip_type" {
  type        = string
  description = "External IP of the VM: none, ephemeral, or static (a regional google_compute_address is created). If null, assign_external_ip decides between none and ephemeral."
  default     = null

  validation {
    condition     = var.external_ip_type == null || contains(["none", "ephemeral", "static"], coalesce(var.external_ip_type, "none"))
    error_message = "external_ip_type must be one of: none, ephemeral, static."
  }
}

variable "assign_external_ip" {
  type        = bool
  description = "Deprecated: use external_ip_type. Attaches an ephemeral external IP when external_ip_type is null."
  default     = false
}

variable "service_account_email" {
  type        = string
  description = "Service account for the VM. If null, the default compute service account is used with logging and monitoring scopes only."
  default     = null
}

variable "create_instance_group" {
  type        = bool
  description = "Whether to create an unmanaged instance group containing the VM"
  default     = true
}

variable "named_port_name" {
  type        = string
  description = "Name of the named port on the instance group"
  default     = "http"
}

variable "named_port" {
  type        = number
  description = "Port number of the named port on the instance group"
  default     = 80
}

variable "create_lb_firewall_rule" {
  type        = bool
  description = "Whether to create a firewall rule allowing GCP health-check and LB proxy ranges to reach the named port"
  default     = true
}
