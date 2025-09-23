variable "vpc_id" {}
variable "igw_id" {}
variable "nat_gateway_id" {}
variable "public_subnets" {
  description = "List of public subnet objects with id and availability_zone"
  type = list(object({
    id                = string
    availability_zone = string
  }))
}
variable "private_subnets" {
  description = "List of private subnet objects with id and availability_zone"
  type = list(object({
    id                = string
    availability_zone = string
  }))
}
variable "tags" { type = map(string) }

variable "create_nat" {
  type    = bool
  default = false
}

# Public Route Tables (per AZ)
resource "aws_route_table" "public" {
  for_each = {
    for s in var.public_subnets : s.availability_zone => s
  }

  vpc_id = var.vpc_id

  tags = merge(var.tags, { Name = "public-rt-${each.key}" })
}

resource "aws_route" "public_igw" {
  for_each = aws_route_table.public

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

resource "aws_route_table_association" "public" {
  for_each = {
    for s in var.public_subnets : s.id => s.availability_zone
  }

  subnet_id      = each.key
  route_table_id = aws_route_table.public[each.value].id
}

# Private Route Tables (per AZ)
resource "aws_route_table" "private" {
  for_each = {
    for s in var.private_subnets : s.availability_zone => s
  }

  vpc_id = var.vpc_id

  tags = merge(var.tags, { Name = "private-rt-${each.key}" })
}

resource "aws_route" "private_nat" {
  for_each = var.create_nat && var.nat_gateway_id != null ? aws_route_table.private : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}

resource "aws_route_table_association" "private" {
  for_each = {
    for s in var.private_subnets : s.id => s.availability_zone
  }

  subnet_id      = each.key
  route_table_id = aws_route_table.private[each.value].id
}

# Outputs
output "public_rt_ids" {
  value = { for k, rt in aws_route_table.public : k => rt.id }
}

output "private_rt_ids" {
  value = { for k, rt in aws_route_table.private : k => rt.id }
}
