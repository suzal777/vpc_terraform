variable "vpc_id" {}
variable "igw_id" {}
variable "nat_gateway_ids" {
  description = "Map of AZ -> NAT Gateway ID"
  type        = map(string)
  default     = {}
}
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
variable "tags" {
  type = map(string)
}

# Group subnets by AZ
locals {
  # public subnets by AZ: map(az -> list of subnets)
  public_subnets_by_az = {
    for az in distinct([for s in var.public_subnets : s.availability_zone]) :
    az => [for s in var.public_subnets : s if s.availability_zone == az]
  }

  # private subnets by AZ: map(az -> list of subnets)
  private_subnets_by_az = {
    for az in distinct([for s in var.private_subnets : s.availability_zone]) :
    az => [for s in var.private_subnets : s if s.availability_zone == az]
  }
}

# -----------------------------
# Public Route Tables (per AZ)
# -----------------------------
resource "aws_route_table" "public" {
  for_each = local.public_subnets_by_az

  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "public-rt-${each.key}" })
}

resource "aws_route" "public_igw" {
  for_each = aws_route_table.public

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

# Public route table associations (one per subnet)
resource "aws_route_table_association" "public" {
  for_each = {
    for s in flatten(values(local.public_subnets_by_az)) : s.id => s
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[each.value.availability_zone].id
}

# -----------------------------
# Private Route Tables (per AZ)
# -----------------------------
resource "aws_route_table" "private" {
  for_each = local.private_subnets_by_az

  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "private-rt-${each.key}" })
}

# NAT Routes (per AZ)
resource "aws_route" "private_nat" {
  for_each = {
    for az, rt in aws_route_table.private : az => rt
    if contains(keys(var.nat_gateway_ids), az)
  }

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_ids[each.key]
}

# Private route table associations (one per subnet)
resource "aws_route_table_association" "private" {
  for_each = {
    for s in flatten(values(local.private_subnets_by_az)) : s.id => s
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.value.availability_zone].id
}
# -----------------------------
# Outputs
# -----------------------------
output "public_rt_ids" {
  value = { for k, rt in aws_route_table.public : k => rt.id }
}

output "private_rt_ids" {
  value = { for k, rt in aws_route_table.private : k => rt.id }
}
