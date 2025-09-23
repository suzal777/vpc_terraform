variable "vpc_id" {}
variable "subnets" {}
variable "tags" { type = map(string) }


resource "aws_subnet" "public" {
for_each = { for idx, sn in var.subnets.public : idx => sn }
vpc_id = var.vpc_id
cidr_block = each.value.cidr
availability_zone = each.value.az


tags = merge(var.tags, { Name = "public-${each.value.az}" })
}


resource "aws_subnet" "private" {
for_each = { for idx, sn in var.subnets.private : idx => sn }
vpc_id = var.vpc_id
cidr_block = each.value.cidr
availability_zone = each.value.az


tags = merge(var.tags, { Name = "private-${each.value.az}" })
}


output "public_ids" {
value = [for s in aws_subnet.public : s.id]
}


output "private_ids" {
value = [for s in aws_subnet.private : s.id]
}