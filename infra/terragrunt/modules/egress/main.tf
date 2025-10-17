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
  tags = var.tags

  vpn_routes = flatten([
    for vpn in var.vpn_connections : [
      for cidr in lookup(vpn, "destination_cidrs", []) : {
        name = vpn.name
        cidr = cidr
      }
    ]
  ])

  additional_egress_cidrs = [for cidr in var.default_egress_cidrs : cidr if cidr != "0.0.0.0/0"]
  has_default_route        = contains(var.default_egress_cidrs, "0.0.0.0/0")
}

resource "aws_dx_gateway" "this" {
  count = var.direct_connect.enabled ? 1 : 0

  name            = var.direct_connect.name
  amazon_side_asn = var.direct_connect.amazon_side_asn
  tags            = merge(local.tags, { Name = var.direct_connect.name })
}

resource "aws_dx_gateway_association" "this" {
  count = var.direct_connect.enabled && var.tgw_id != null ? 1 : 0

  dx_gateway_id         = aws_dx_gateway.this[0].id
  associated_gateway_id = var.tgw_id

  allowed_prefixes = var.direct_connect.allowed_prefixes
}

resource "aws_ec2_transit_gateway_route_table" "egress" {
  count = var.create_egress_route_table && var.tgw_id != null ? 1 : 0

  transit_gateway_id = var.tgw_id
  tags               = merge(local.tags, { Name = "${var.name}-egress" })
}

resource "aws_ec2_transit_gateway_route" "default_internet" {
  count = var.create_egress_route_table && var.tgw_id != null && var.internet_attachment_id != null && local.has_default_route ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.internet_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress[0].id
}

resource "aws_ec2_transit_gateway_route" "wan_prefixes" {
  for_each = var.create_egress_route_table && var.tgw_id != null && var.internet_attachment_id != null ? toset(local.additional_egress_cidrs) : []

  destination_cidr_block         = each.key
  transit_gateway_attachment_id  = var.internet_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress[0].id
}

resource "aws_vpn_connection" "this" {
  for_each = { for vpn in var.vpn_connections : vpn.name => vpn }

  transit_gateway_id  = coalesce(each.value.transit_gateway_id, var.tgw_id)
  customer_gateway_id = each.value.customer_gateway_id
  type                = "ipsec.1"
  static_routes_only  = lookup(each.value, "static_routes_only", false)

  tunnel1_inside_cidr = lookup(each.value, "tunnel1_inside_cidr", null)
  tunnel2_inside_cidr = lookup(each.value, "tunnel2_inside_cidr", null)
  tunnel1_preshared_key = lookup(each.value, "tunnel1_preshared_key", null)
  tunnel2_preshared_key = lookup(each.value, "tunnel2_preshared_key", null)

  tags = merge(local.tags, { Name = "${var.name}-${each.key}" })
}

resource "aws_ec2_transit_gateway_route" "vpn_routes" {
  for_each = var.create_egress_route_table && var.tgw_id != null ? { for route in local.vpn_routes : "${route.name}:${route.cidr}" => route } : {}

  destination_cidr_block         = each.value.cidr
  transit_gateway_attachment_id  = aws_vpn_connection.this[each.value.name].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress[0].id
}

output "dx_gateway_id" {
  value       = try(aws_dx_gateway.this[0].id, null)
  description = "Direct Connect gateway ID"
}

output "vpn_connection_ids" {
  value       = [for v in aws_vpn_connection.this : v.id]
  description = "VPN connection IDs"
}

output "egress_route_table_id" {
  value       = try(aws_ec2_transit_gateway_route_table.egress[0].id, null)
  description = "Transit Gateway route table used for egress"
}
