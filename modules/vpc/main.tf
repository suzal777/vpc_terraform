#-----------------VPC--------------------------------#
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${var.name}-vpc" })
}

#-----------------Subnets---------------------------#
resource "aws_subnet" "public" {
  for_each = { for idx, sn in var.subnets.public : idx => sn }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, { Name = "${var.name}-pub-subnet" })
}

resource "aws_subnet" "private" {
  for_each = { for idx, sn in var.subnets.private : idx => sn }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, { Name = "${var.name}-pvt-subnet" })
}

#-----------------Internet Gateway-------------------#
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

#-----------------NAT Gateways / Instances----------#
# Pick one public subnet per AZ
locals {
  public_subnet_per_az = {
    for az in distinct([for s in aws_subnet.public : s.availability_zone]) :
    az => [for s in aws_subnet.public : s if s.availability_zone == az][0]
  }
}

# NAT EIPs
resource "aws_eip" "nat" {
  for_each = var.create_nat ? local.public_subnet_per_az : {}

  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-nat-eip-${each.key}" })
}

# NAT Gateways
resource "aws_nat_gateway" "nat_gateway" {
  for_each = var.create_nat ? local.public_subnet_per_az : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(var.tags, { Name = "${var.name}-nat-gw-${each.key}" })
}

# NAT Instances
resource "aws_instance" "nat" {
  for_each = var.create_nat_instance ? local.public_subnet_per_az : {}

  ami                         = "ami-024cf76afbc833688" # NAT AMI
  instance_type               = "t3.micro"
  subnet_id                   = each.value.id
  associate_public_ip_address = true
  source_dest_check           = false
  iam_instance_profile = var.iam_instance_profile
  vpc_security_group_ids = var.nat_instance_sg_ids

  tags = merge(var.tags, { Name = "${var.name}-nat-instance" })
}

#-----------------Route Tables-----------------------#
# Group subnets by AZ
locals {
  public_subnets_by_az  = { for az in distinct([for s in aws_subnet.public : s.availability_zone]) : az => [for s in aws_subnet.public : s if s.availability_zone == az] }
  private_subnets_by_az = { for az in distinct([for s in aws_subnet.private : s.availability_zone]) : az => [for s in aws_subnet.private : s if s.availability_zone == az] }
}

# Public Route Tables
resource "aws_route_table" "public" {
  for_each = local.public_subnets_by_az
  vpc_id   = aws_vpc.vpc.id
  tags     = merge(var.tags, { Name = "${var.name}-pub-rt-${each.key}" })
}

resource "aws_route" "public_igw" {
  for_each             = aws_route_table.public
  route_table_id       = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id           = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  for_each = { for idx, subnet in aws_subnet.public : "${subnet.availability_zone}-${idx}" => subnet }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[each.value.availability_zone].id
}

# Private Route Tables
resource "aws_route_table" "private" {
  for_each = local.private_subnets_by_az
  vpc_id   = aws_vpc.vpc.id
  tags     = merge(var.tags, { Name = "${var.name}-pvt-rt-${each.key}" })
}

# Private NAT routes
resource "aws_route" "private_nat_gateway" {
  for_each = { for az, rt in aws_route_table.private : az => rt if contains(keys(aws_nat_gateway.nat_gateway), az) }
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway[each.key].id
}

resource "aws_route" "private_nat_instance" {
  for_each = { for az, rt in aws_route_table.private : az => rt if contains(keys(aws_instance.nat), az) }
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat[each.key].primary_network_interface_id
}

resource "aws_route_table_association" "private" {
  for_each = { for idx, subnet in aws_subnet.private : "${subnet.availability_zone}-${idx}" => subnet }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.value.availability_zone].id
}


