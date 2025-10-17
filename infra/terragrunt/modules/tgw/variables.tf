variable "name" {
  description = "Transit gateway name"
  type        = string
}

variable "amazon_side_asn" {
  description = "Amazon side ASN"
  type        = number
  default     = 64512
}

variable "auto_accept_shared_attachments" {
  description = "Auto accept shared attachments"
  type        = bool
  default     = false
}

variable "default_route_table_association" {
  description = "Enable default association"
  type        = bool
  default     = false
}

variable "default_route_table_propagation" {
  description = "Enable default propagation"
  type        = bool
  default     = false
}

variable "dns_support" {
  description = "DNS support"
  type        = bool
  default     = true
}

variable "vpn_ecmp_support" {
  description = "Enable VPN ECMP"
  type        = bool
  default     = true
}

variable "multicast_support" {
  description = "Enable multicast"
  type        = bool
  default     = false
}

variable "route_tables" {
  description = "Transit gateway route tables"
  type = list(object({
    name    = string
    purpose = optional(string)
  }))
  default = []
}

variable "vpc_attachments" {
  description = "VPC attachments"
  type = list(object({
    name                   = string
    vpc_id                 = string
    subnet_ids             = list(string)
    appliance_mode_support = optional(bool, false)
    dns_support            = optional(bool, true)
    ipv6_support           = optional(bool, false)
    route_table_name       = optional(string)
    propagate_route_tables = optional(list(string), [])
    static_routes          = optional(list(string), [])
  }))
  default = []
}

variable "peering_attachments" {
  description = "Peering attachments to other TGWs"
  type = list(object({
    name                    = string
    peer_account_id         = string
    peer_region             = string
    peer_transit_gateway_id = string
    route_table_name        = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
