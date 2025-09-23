region = "us-west-2"

vpc_name = "Sujal-VPC"

vpc_cidr = "10.0.0.0/16"


tags = {
  Project = "Terraform"
  Env     = "Main"
  Owner   = "Sujal Phaiju"
}


subnets = {
  public = [
    { cidr = "10.0.1.0/24", az = "us-west-2a" },
    { cidr = "10.0.2.0/24", az = "us-west-2b" },
    { cidr = "10.0.3.0/24", az = "us-west-2b" },
    { cidr = "10.0.4.0/24", az = "us-west-2c" }

  ]
  private = [
    { cidr = "10.0.101.0/24", az = "us-west-2a" },
    { cidr = "10.0.102.0/24", az = "us-west-2b" },
    { cidr = "10.0.103.0/24", az = "us-west-2a" },
    { cidr = "10.0.104.0/24", az = "us-west-2a" },
    { cidr = "10.0.105.0/24", az = "us-west-2b" },
    { cidr = "10.0.106.0/24", az = "us-west-2c" }
  ]
}

vpc_endpoints = ["s3", "dynamodb"]

create_nat = true