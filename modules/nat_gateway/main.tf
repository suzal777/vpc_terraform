#-----------------------------------------------------#
#----------------VARIABLE SECTION---------------------#
#-----------------------------------------------------#

variable "vpc_id" {
  description = "VPC ID where NAT gateways or NAT instances will be created"
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

variable "create_nat_instance" {
  description = "Whether to create NAT Instances instead of Gateways"
  type        = bool
  default     = false
}

# Pick one subnet per AZ
locals {
  public_subnet_per_az = {
    for az in distinct([for sn in var.public_subnets : sn.availability_zone]) :
    az => [for sn in var.public_subnets : sn if sn.availability_zone == az][0]
  }
}

#-----------------------------------------------------#
#-----------------RESOURCE SECTION--------------------#
#-----------------------------------------------------#

# Elastic IP per AZ (only if NAT Gateway)
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

# NAT Instance per AZ
resource "aws_instance" "nat" {
  for_each = var.create_nat_instance ? local.public_subnet_per_az : {}

  ami                    = "ami-024cf76afbc833688"
  instance_type          = "t3.micro"
  subnet_id              = each.value.id
  associate_public_ip_address = true
  source_dest_check      = false # REQUIRED for NAT instances

  tags = merge(var.tags, { Name = "nat-instance-${each.key}" })
}

#-----------------------------------------------------#
#------------------OUTPUTS SECTION--------------------#
#-----------------------------------------------------#

output "nat_ids_by_az" {
  value = var.create_nat ? { for az, nat in aws_nat_gateway.this : az => nat.id } : var.create_nat_instance ? { for az, inst in aws_instance.nat : az => inst.id } : {}
}

output "nat_eni_ids_by_az" {
  value = {
    for az, inst in aws_instance.nat : az => inst.primary_network_interface_id
  }
}