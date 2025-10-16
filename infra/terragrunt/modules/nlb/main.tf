
variable "name" { type = string }
variable "subnet_ids" { type = list(string) }
variable "tags" { type = map(string) }

resource "aws_lb" "nlb" {
  name               = var.name
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnet_ids
  enable_cross_zone_load_balancing = true
  tags = var.tags
}

output "nlb_arn" { value = aws_lb.nlb.arn }
output "nlb_dns" { value = aws_lb.nlb.dns_name }
