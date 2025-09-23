variable "name" {}
variable "cidr_block" {}
variable "tags" { type = map(string) }


resource "aws_vpc" "this" {
cidr_block = var.cidr_block
enable_dns_support = true
enable_dns_hostnames = true


tags = merge(var.tags, { Name = var.name })
}


output "vpc_id" {
value = aws_vpc.this.id
}