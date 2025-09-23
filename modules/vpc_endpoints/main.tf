variable "vpc_id" {}
variable "services" { type = list(string) }
variable "subnets" {}
variable "tags" { type = map(string) }


resource "aws_vpc_endpoint" "this" {
for_each = toset(var.services)


vpc_id = var.vpc_id
service_name = "com.amazonaws.${var.tags["Region"]}.${each.value}"
vpc_endpoint_type = each.value == "s3" ? "Gateway" : "Interface"


subnet_ids = each.value == "s3" ? null : var.subnets


tags = merge(var.tags, { Name = "endpoint-${each.value}" })
}


output "endpoint_ids" {
value = { for k, v in aws_vpc_endpoint.this : k => v.id }
}