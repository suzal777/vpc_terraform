variable "vpc_id" {}
variable "igw_id" {}
variable "nat_gateway_id" {}
variable "public_subnets" {}
variable "private_subnets" {}
variable "tags" { type = map(string) }


# Public Route Table
resource "aws_route_table" "public" {
vpc_id = var.vpc_id


route {
cidr_block = "0.0.0.0/0"
gateway_id = var.igw_id
}


tags = merge(var.tags, { Name = "public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each = { for idx, subnet in var.public_subnets : "public-${idx}" => subnet }
  subnet_id      = each.value
  route_table_id = aws_route_table.public.id
}


# Private Route Table
resource "aws_route_table" "private" {
vpc_id = var.vpc_id


route {
cidr_block = "0.0.0.0/0"
nat_gateway_id = var.nat_gateway_id
}


tags = merge(var.tags, { Name = "private-rt" })
}


resource "aws_route_table_association" "private" {
  for_each = { for idx, subnet in var.private_subnets : "private-${idx}" => subnet }
  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}


output "public_rt_id" {
value = aws_route_table.public.id
}


output "private_rt_id" {
value = aws_route_table.private.id
}