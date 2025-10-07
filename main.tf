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
    },
    {
      description = "Allow HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
      {
      description = "Allow 8080 from anywhere"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTPS from anywhere"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow SSH from anywhere"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "ecs" {
  source      = "./modules/ecs"

  name        = "sujal-ecs-cluster"
  region      = var.region
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = [for s in module.vpc.public_subnets : s.id]
  private_subnet_ids   = [for s in module.vpc.private_subnets : s.id]
  sg_ids       = [module.nat_sg.sg_id]
  tags        = var.tags
  launch_type = "EC2"  # "EC2" or "FARGATE"

  # Required
  image_id = "ami-036428f37186903ce"  # Only used for EC2, still required
  

  services = [
    {
      name                   = "frontend"
      task_image             = "suzal777/ecs-frontend:1.0.4"
      task_cpu               = 256
      task_memory            = 256
      desired_count          = 1
      enable_service_connect = true
      enable_load_balancer   = true
      container_port         = 80
      host_port              = 80
      path_pattern           = "/*"
    },
    {
      name                   = "backend"
      task_image             = "suzal777/ecs-backend:1.0.2"
      task_cpu               = 256
      task_memory            = 256
      desired_count          = 1
      enable_service_connect = true
      enable_load_balancer   = false
      container_port         = 8080
      host_port              = 8080
    }
  ]
}

# Working till now