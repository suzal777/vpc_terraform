variable "vpc_id" {
  description = "VPC ID where NAT gateway will be created"
  type        = string
}

variable "public_subnet" {
  description = "Public subnet ID where NAT gateway should be deployed"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "create_nat" {
  description = "Whether to create NAT Gateway and EIP"
  type        = bool
  default     = false
}

# Elastic IP for NAT
resource "aws_eip" "nat" {
  count  = var.create_nat ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, { Name = "nat-eip" })
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = var.create_nat ? 1 : 0
  allocation_id = var.create_nat ? aws_eip.nat[0].id : null
  subnet_id     = var.public_subnet

  tags = merge(var.tags, { Name = "nat-gw" })
}

# Output NAT Gateway ID (null if not created)
output "nat_id" {
  value = var.create_nat ? aws_nat_gateway.this[0].id : null
}
