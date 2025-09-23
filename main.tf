provider "aws" {
region = var.region
}


module "vpc" {
source = "./modules/vpc"


name = var.vpc_name
cidr_block = var.vpc_cidr
tags = var.tags
}


module "subnets" {
source = "./modules/subnets"
vpc_id = module.vpc.vpc_id
subnets = var.subnets
tags = var.tags
}


module "igw" {
source = "./modules/igw"
vpc_id = module.vpc.vpc_id
tags = var.tags
}


module "nat" {
  source        = "./modules/nat_gateway"
  vpc_id        = module.vpc.vpc_id
  public_subnet = module.subnets.public_ids[0]
  create_nat    = var.create_nat   # toggle this in .tfvars to enable/disable NAT
  tags          = var.tags
}



module "route_tables" {
source = "./modules/route_tables"
vpc_id = module.vpc.vpc_id
igw_id = module.igw.igw_id
nat_gateway_id  = module.nat.nat_id
create_nat      = var.create_nat
public_subnets  = module.subnets.public_subnets   # <-- updated
private_subnets = module.subnets.private_subnets  # <-- updated
tags = var.tags
}


# module "endpoints" {
# source = "./modules/vpc_endpoints"
# vpc_id = module.vpc.vpc_id
# region   = var.region
# services = var.vpc_endpoints
# subnets = module.subnets.private_ids
# tags = var.tags
# }