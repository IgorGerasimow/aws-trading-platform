variable "name" {
  description = "Edge stack name"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "global_accelerator" {
  description = "Global Accelerator configuration"
  type = object({
    enabled                = bool
    name                   = string
    protocol               = string
    listener_port          = number
    health_check_protocol  = string
    health_check_port      = number
    endpoint_groups        = list(object({
      region                = string
      traffic_dial_percentage = optional(number, 100)
      health_check_interval_seconds = optional(number, 30)
      threshold_count       = optional(number, 3)
      endpoints             = list(object({
        endpoint_id = string
        weight      = optional(number, 128)
      }))
    }))
  })
  default = {
    enabled               = false
    name                  = "trading-ga"
    protocol              = "TCP"
    listener_port         = 443
    health_check_protocol = "TCP"
    health_check_port     = 443
    endpoint_groups       = []
  }
}

variable "cloudfront" {
  description = "CloudFront distribution settings"
  type = object({
    enabled              = bool
    origin_domain_name   = string
    origin_protocol_policy = string
    allowed_methods      = list(string)
    cached_methods       = list(string)
    price_class          = string
    acm_certificate_arn  = string
    aliases              = list(string)
    default_ttl          = number
    max_ttl              = number
    min_ttl              = number
    compress             = bool
  })
  default = {
    enabled               = false
    origin_domain_name    = ""
    origin_protocol_policy = "https-only"
    allowed_methods       = ["GET", "HEAD"]
    cached_methods        = ["GET", "HEAD"]
    price_class           = "PriceClass_All"
    acm_certificate_arn   = ""
    aliases               = []
    default_ttl           = 60
    max_ttl               = 300
    min_ttl               = 0
    compress              = true
  }
}
