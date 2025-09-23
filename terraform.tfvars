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
{ cidr = "10.0.2.0/24", az = "us-east-1b" },
{ cidr = "10.0.3.0/24", az = "us-east-1c" },
{ cidr = "10.0.4.0/24", az = "us-east-1d" },
{ cidr = "10.0.5.0/24", az = "us-east-1e" },
{ cidr = "10.0.6.0/24", az = "us-east-1f" }
]
private = [
{ cidr = "10.0.101.0/24", az = "us-east-1a" },
{ cidr = "10.0.102.0/24", az = "us-east-1b" },
{ cidr = "10.0.103.0/24", az = "us-east-1c" },
{ cidr = "10.0.104.0/24", az = "us-east-1d" },
{ cidr = "10.0.105.0/24", az = "us-east-1e" },
{ cidr = "10.0.106.0/24", az = "us-east-1f" }
]
}

vpc_endpoints = ["s3", "dynamodb"]

create_nat = false