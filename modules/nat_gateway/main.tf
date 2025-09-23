variable "vpc_id" {
  description = "VPC ID where NAT gateways will be created"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet objects with id and availability_zone"
  type = list(object({
    id                = string
    availability_zone = string
  }))
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "create_nat" {
  description = "Whether to create NAT Gateways and EIPs"
  type        = bool
  default     = false
}

# Pick one subnet per AZ
locals {
  public_subnet_per_az = {
    for az, subnets in {for sn in var.public_subnets : sn.availability_zone => []} :
    az => [for sn in var.public_subnets : sn if sn.availability_zone == az][0]
  }
}

# Elastic IP per AZ
resource "aws_eip" "nat" {
  for_each = var.create_nat ? local.public_subnet_per_az : {}

  domain = "vpc"
  tags   = merge(var.tags, { Name = "nat-eip-${each.key}" })
}

# NAT Gateway per AZ
resource "aws_nat_gateway" "this" {
  for_each = var.create_nat ? local.public_subnet_per_az : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(var.tags, { Name = "nat-gw-${each.key}" })
}

# Output: map of AZ -> NAT Gateway ID
output "nat_ids_by_az" {
  value = { for az, nat in aws_nat_gateway.this : az => nat.id }
}
