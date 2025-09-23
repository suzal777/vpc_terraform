variable "vpc_id" {}
variable "tags" { type = map(string) }


resource "aws_internet_gateway" "this" {
vpc_id = var.vpc_id


tags = merge(var.tags, { Name = "igw" })
}


output "igw_id" {
value = aws_internet_gateway.this.id
}