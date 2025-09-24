output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = [for s in aws_subnet.public : { id = s.id, az = s.availability_zone }]
}

output "private_subnets" {
  value = [for s in aws_subnet.private : { id = s.id, az = s.availability_zone }]
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "nat_ids" {
  value = var.create_nat ? { for k, v in aws_nat_gateway.nat_gateway : k => v.id } : var.create_nat_instance ? { for k, v in aws_instance.nat : k => v.id } : {}
}

output "public_rt_ids" {
  value = { for k, rt in aws_route_table.public : k => rt.id }
}

output "private_rt_ids" {
  value = { for k, rt in aws_route_table.private : k => rt.id }
}