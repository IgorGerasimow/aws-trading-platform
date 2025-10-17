terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  tags               = var.tags
  accelerator_config = var.global_accelerator
  cloudfront_config  = var.cloudfront
  endpoint_groups    = { for eg in var.global_accelerator.endpoint_groups : eg.region => eg }
}

resource "aws_globalaccelerator_accelerator" "this" {
  count = local.accelerator_config.enabled ? 1 : 0

  name               = local.accelerator_config.name
  ip_address_type    = "IPV4"
  enabled            = true
  tags               = merge(local.tags, { Name = local.accelerator_config.name })
}

resource "aws_globalaccelerator_listener" "this" {
  count = local.accelerator_config.enabled ? 1 : 0

  accelerator_arn = aws_globalaccelerator_accelerator.this[0].id
  protocol        = local.accelerator_config.protocol

  port_range {
    from_port = local.accelerator_config.listener_port
    to_port   = local.accelerator_config.listener_port
  }
}

resource "aws_globalaccelerator_endpoint_group" "this" {
  for_each = local.accelerator_config.enabled ? local.endpoint_groups : {}

  listener_arn          = aws_globalaccelerator_listener.this[0].id
  endpoint_group_region = each.value.region
  health_check_protocol = lookup(each.value, "health_check_protocol", local.accelerator_config.health_check_protocol)
  health_check_port     = lookup(each.value, "health_check_port", local.accelerator_config.health_check_port)
  traffic_dial_percentage = lookup(each.value, "traffic_dial_percentage", 100)
  health_check_interval_seconds = lookup(each.value, "health_check_interval_seconds", 30)
  threshold_count       = lookup(each.value, "threshold_count", 3)

  dynamic "endpoint_configuration" {
    for_each = each.value.endpoints
    content {
      endpoint_id = endpoint_configuration.value.endpoint_id
      weight      = lookup(endpoint_configuration.value, "weight", 128)
    }
  }

  tags = merge(local.tags, { Name = "${var.name}-${each.value.region}" })
}

resource "aws_cloudfront_origin_access_control" "this" {
  count = local.cloudfront_config.enabled ? 1 : 0

  name                              = "${var.name}-oac"
  description                       = "OAC for ${var.name}"
  origin_access_control_origin_type = "custom"
  signing_behavior                  = "never"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  count = local.cloudfront_config.enabled ? 1 : 0

  enabled             = true
  comment             = "${var.name} edge distribution"
  price_class         = local.cloudfront_config.price_class
  default_root_object = ""
  aliases             = local.cloudfront_config.aliases

  origin {
    domain_name = local.cloudfront_config.origin_domain_name
    origin_id   = "${var.name}-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = local.cloudfront_config.origin_protocol_policy
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
  }

  default_cache_behavior {
    allowed_methods  = local.cloudfront_config.allowed_methods
    cached_methods   = local.cloudfront_config.cached_methods
    target_origin_id = "${var.name}-origin"

    forwarded_values {
      query_string = true
      headers      = ["*" ]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = local.cloudfront_config.compress
    default_ttl            = local.cloudfront_config.default_ttl
    min_ttl                = local.cloudfront_config.min_ttl
    max_ttl                = local.cloudfront_config.max_ttl
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = local.cloudfront_config.acm_certificate_arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(local.tags, { Name = "${var.name}-cloudfront" })
}

output "global_accelerator_arn" {
  value       = try(aws_globalaccelerator_accelerator.this[0].id, null)
  description = "Global Accelerator ARN"
}

output "cloudfront_distribution_id" {
  value       = try(aws_cloudfront_distribution.this[0].id, null)
  description = "CloudFront distribution ID"
}
