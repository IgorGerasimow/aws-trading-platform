variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "tgw_id" {
  description = "Transit Gateway ID"
  type        = string
  default     = null
}

variable "internet_attachment_id" {
  description = "Attachment ID providing internet egress"
  type        = string
  default     = null
}

variable "default_egress_cidrs" {
  description = "Default CIDRs to route toward the internet attachment"
  type        = list(string)
  default     = []
}

variable "create_egress_route_table" {
  description = "Whether to manage a dedicated egress route table"
  type        = bool
  default     = true
}

variable "direct_connect" {
  description = "Direct Connect configuration"
  type = object({
    enabled          = bool
    name             = string
    amazon_side_asn  = number
    allowed_prefixes = list(string)
  })
  default = {
    enabled          = false
    name             = "dx-egress"
    amazon_side_asn  = 64512
    allowed_prefixes = []
  }
}

variable "vpn_connections" {
  description = "VPN connections to create"
  type = list(object({
    name                  = string
    customer_gateway_id   = string
    transit_gateway_id    = optional(string)
    static_routes_only    = optional(bool)
    tunnel1_inside_cidr   = optional(string)
    tunnel2_inside_cidr   = optional(string)
    tunnel1_preshared_key = optional(string)
    tunnel2_preshared_key = optional(string)
    destination_cidrs     = optional(list(string), [])
  }))
  default = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
