region = "us-east-1"

vpc_name = "Sujal-VPC"

vpc_cidr = "10.0.0.0/16"


tags = {
Project = "Terraform"
Env = "Main"
Owner = "Sujal Phaiju"
}


subnets = {
public = [
{ cidr = "10.0.1.0/24", az = "us-east-1a" },
{ cidr = "10.0.2.0/24", az = "us-east-1b" }
]
private = [
{ cidr = "10.0.101.0/24", az = "us-east-1a" },
{ cidr = "10.0.102.0/24", az = "us-east-1b" }
]
}

vpc_endpoints = ["s3", "dynamodb"]

create_nat = false