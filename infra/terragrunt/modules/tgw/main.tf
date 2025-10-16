
variable "name" { type = string }
variable "tags" { type = map(string) }

resource "aws_ec2_transit_gateway" "this" {
  description = var.name
  tags        = merge(var.tags, { Name = var.name })
}

output "tgw_id" { value = aws_ec2_transit_gateway.this.id }
