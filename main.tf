provider "aws" {
  region = var.region
}

module "vpc" {
  source             = "./modules/vpc"
  name               = var.vpc_name
  cidr_block         = var.vpc_cidr
  tags               = var.tags
  subnets            = var.subnets
  create_nat         = var.create_nat
  create_nat_instance = var.create_nat_instance
  iam_instance_profile = module.iam_nat.instance_profile
  nat_instance_sg_ids = [module.nat_sg.sg_id]

}

module "iam_nat" {
  source              = "./modules/iam"
  name                = "vpc"
  tags                = var.tags
  create_nat_instance = var.create_nat_instance
}

module "nat_sg" {
  source = "./modules/security_group"
  name   = "nat-instance-sg"
  vpc_id = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
  tags   = var.tags
  
  ingress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [var.vpc_cidr]
    }
  ]
}
