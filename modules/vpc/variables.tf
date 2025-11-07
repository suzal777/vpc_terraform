variable "name" {}
variable "cidr_block" {}
variable "tags" {
  type = map(string)
}

variable "subnets" {
  type = object({
    public  = list(object({ cidr = string, az = string }))
    private = list(object({ cidr = string, az = string }))
  })
}

variable "create_nat" {
  type    = bool
  default = false
}

variable "create_nat_instance" {
  type    = bool
  default = false
}