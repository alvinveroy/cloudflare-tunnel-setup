# terraform/modules/tunnel/variables.tf
# Input variables for the tunnel module

variable "account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "tunnel_name" {
  description = "Name of the Cloudflare Tunnel"
  type        = string
}

variable "services" {
  description = "List of services to expose via the tunnel"
  type = list(object({
    subdomain = string
    local_ip  = string
    port      = number
    type      = string
  }))
  validation {
    condition     = alltrue([for s in var.services : contains(["http", "tcp", "ssh"], s.type)])
    error_message = "Service type must be one of: http, tcp, ssh."
  }
}

variable "domain" {
  description = "Primary domain for public-facing services (e.g., example.com)"
  type        = string
}

variable "local_domain" {
  description = "Local domain for internal resolution (e.g., example.local)"
  type        = string
}

variable "bind_ip" {
  description = "Private IP of the Bind DNS server"
  type        = string
  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.bind_ip))
    error_message = "Bind IP must be a valid IPv4 address."
  }
}

variable "zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
}

variable "virtual_network_id" {
  description = "Virtual Network ID for WARP routing"
  type        = string
}