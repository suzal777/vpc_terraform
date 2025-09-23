variable "vpc_id" {}
variable "public_subnet" {}
variable "allocate_eip" { default = true }
variable "tags" { type = map(string) }


resource "aws_eip" "nat" {
count = var.allocate_eip ? 1 : 0
domain = "vpc"
}


resource "aws_nat_gateway" "this" {
allocation_id = var.allocate_eip ? aws_eip.nat[0].id : null
subnet_id = var.public_subnet


tags = merge(var.tags, { Name = "nat-gw" })
}


output "nat_id" {
value = aws_nat_gateway.this.id
}