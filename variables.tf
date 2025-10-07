variable "region" {}
variable "vpc_name" {}
variable "vpc_cidr" {}


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
  description = "Whether to create NAT Instances instead of Gateways"
  type        = bool
  default     = false
}

variable "ecr_name" {}