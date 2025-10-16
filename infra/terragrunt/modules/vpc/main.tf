
variable "name" { type = string }
variable "cidr" { type = string }
variable "azs"  { type = list(string) }
variable "public_subnets"  { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "tags" { type = map(string) }

data "aws_caller_identity" "current" {}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = element(var.azs, index(var.public_subnets, each.value) % length(var.azs))
  tags = merge(var.tags, { Name = "${var.name}-public-${replace(each.value, "/", "-")}", "kubernetes.io/role/elb"="1" })
}

resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = element(var.azs, index(var.private_subnets, each.value) % length(var.azs))
  tags = merge(var.tags, { Name = "${var.name}-private-${replace(each.value, "/", "-")}", "kubernetes.io/role/internal-elb"="1" })
}

output "vpc_id"            { value = aws_vpc.this.id }
output "public_subnet_ids" { value = [for s in aws_subnet.public  : s.id] }
output "private_subnet_ids"{ value = [for s in aws_subnet.private : s.id] }
