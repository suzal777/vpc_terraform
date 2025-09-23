variable "region" {}
variable "vpc_name" {}
variable "vpc_cidr" {}


variable "tags" {
type = map(string)
}


variable "subnets" {
type = object({
public = list(object({ cidr = string, az = string }))
private = list(object({ cidr = string, az = string }))
})
}


variable "vpc_endpoints" {
type = list(string)
default = []
}
