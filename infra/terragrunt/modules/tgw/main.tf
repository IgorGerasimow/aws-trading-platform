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
  tags         = var.tags
  route_tables = { for rt in var.route_tables : rt.name => rt }
  vpc_attach   = { for att in var.vpc_attachments : att.name => att }
  peer_attach  = { for peer in var.peering_attachments : peer.name => peer }

  propagation_map = {
    for entry in flatten([
      for att in var.vpc_attachments : [
        for rt in lookup(att, "propagate_route_tables", []) : {
          key        = "${att.name}:${rt}"
          attachment = att.name
          route      = rt
        }
      ]
    ]) : entry.key => {
      attachment = entry.attachment
      route      = entry.route
    }
  }

  static_route_map = {
    for entry in flatten([
      for att in var.vpc_attachments : [
        for cidr in lookup(att, "static_routes", []) : {
          key        = "${att.name}:${cidr}"
          attachment = att.name
          cidr       = cidr
          route      = lookup(att, "route_table_name", null)
        }
      ]
    ]) : entry.key => {
      attachment = entry.attachment
      cidr       = entry.cidr
      route      = entry.route
    }
  }
}

resource "aws_ec2_transit_gateway" "this" {
  description = var.name

  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments ? "enable" : "disable"
  default_route_table_association = var.default_route_table_association ? "enable" : "disable"
  default_route_table_propagation = var.default_route_table_propagation ? "enable" : "disable"
  dns_support                     = var.dns_support ? "enable" : "disable"
  vpn_ecmp_support                = var.vpn_ecmp_support ? "enable" : "disable"
  multicast_support               = var.multicast_support ? "enable" : "disable"

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each = local.route_tables

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = merge(
    local.tags,
    { Name = each.value.name },
    lookup(each.value, "purpose", null) != null ? { Purpose = each.value.purpose } : {}
  )
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = local.vpc_attach

  subnet_ids         = each.value.subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = each.value.vpc_id

  appliance_mode_support = lookup(each.value, "appliance_mode_support", false) ? "enable" : "disable"
  dns_support            = lookup(each.value, "dns_support", true) ? "enable" : "disable"
  ipv6_support           = lookup(each.value, "ipv6_support", false) ? "enable" : "disable"

  tags = merge(local.tags, { Name = each.key })
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = { for att in var.vpc_attachments : att.name => att if lookup(att, "route_table_name", null) != null }

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_name].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = local.propagation_map

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.value.attachment].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route].id
}

resource "aws_ec2_transit_gateway_route" "static" {
  for_each = local.static_route_map

  destination_cidr_block         = each.value.cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.value.attachment].id
  transit_gateway_route_table_id = each.value.route != null ? aws_ec2_transit_gateway_route_table.this[each.value.route].id : aws_ec2_transit_gateway.this.association_default_route_table_id
}

resource "aws_ec2_transit_gateway_peering_attachment" "this" {
  for_each = local.peer_attach

  transit_gateway_id      = aws_ec2_transit_gateway.this.id
  peer_account_id         = each.value.peer_account_id
  peer_region             = each.value.peer_region
  peer_transit_gateway_id = each.value.peer_transit_gateway_id

  tags = merge(local.tags, { Name = each.key })
}

resource "aws_ec2_transit_gateway_route_table_association" "peering" {
  for_each = { for peer in var.peering_attachments : peer.name => peer if lookup(peer, "route_table_name", null) != null }

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.this[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_name].id
}

output "tgw_id" {
  description = "Transit gateway ID"
  value       = aws_ec2_transit_gateway.this.id
}

output "route_table_ids" {
  description = "Transit gateway route table IDs"
  value       = { for name, rt in aws_ec2_transit_gateway_route_table.this : name => rt.id }
}

output "vpc_attachment_ids" {
  description = "Transit gateway VPC attachment IDs"
  value       = { for name, att in aws_ec2_transit_gateway_vpc_attachment.this : name => att.id }
}

output "peering_attachment_ids" {
  description = "Transit gateway peering attachment IDs"
  value       = { for name, att in aws_ec2_transit_gateway_peering_attachment.this : name => att.id }
}
