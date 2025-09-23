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

# Elastic IP per AZ
resource "aws_eip" "nat" {
  for_each = var.create_nat ? { for sn in var.public_subnets : sn.availability_zone => sn } : {}

  domain = "vpc"
  tags   = merge(var.tags, { Name = "nat-eip-${each.key}" })
}

# NAT Gateway per AZ
resource "aws_nat_gateway" "this" {
  for_each = var.create_nat ? { for sn in var.public_subnets : sn.availability_zone => sn } : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(var.tags, { Name = "nat-gw-${each.key}" })
}

# Outputs (map of AZ → NAT ID)
output "nat_ids" {
  value = { for k, nat in aws_nat_gateway.this : k => nat.id }
}

output "nat_ids_by_az" {
  value = { for i, nat in aws_nat_gateway.this : nat.availability_zone => nat.id }
}
