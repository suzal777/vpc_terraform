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

module "alb_sg" {
  source = "./modules/security_group"
  name   = "alb-sg"
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
      description = "Allow HTTPS from anywhere"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "ecs_sg" {
  source = "./modules/security_group"
  name   = "ecs-sg"
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
    }
  ]
}

# module "ecr" {
#   source  = "./modules/ecr"
#   name    = "sujal-ecs"
#   region  = var.region
#   tags    = var.tags

#   services = [
#     {
#       name       = "frontend"
#       task_image = "suzal777/ecs-frontend:1.0.5"
#     },
#     {
#       name       = "backend"
#       task_image = "suzal777/ecs-backend:1.0.2"
#     }
#   ]
# }

# module "ecs" {
#   source      = "./modules/ecs"

#   name        = "sujal"
#   region      = var.region
#   vpc_id       = module.vpc.vpc_id
#   subnet_ids   = [for s in module.vpc.public_subnets : s.id]
#   private_subnet_ids   = [for s in module.vpc.private_subnets : s.id]
#   sg_ids = {
#   alb_sg = [module.alb_sg.sg_id]
#   ecs_sg = [module.ecs_sg.sg_id]
#   }
#   tags        = var.tags
#   launch_type = "EC2"  # "EC2" or "FARGATE"
#   enable_fargate_spot = true

#   image_id = "ami-036428f37186903ce"  # Only used for EC2
#   repository_urls = module.ecr.repository_urls

#   services = [
#     {
#       name                   = "frontend"
#       task_image             = "${module.ecr.repository_urls["frontend"]}:latest"
#       task_cpu               = 256
#       task_memory            = 512
#       desired_count          = 1
#       enable_service_connect = false
#       enable_load_balancer   = true
#       container_port         = 80
#       host_port              = 80
#       path_pattern           = "/*"
#       health_check_path      = "/"
#     },
#     {
#       name                   = "backend"
#       task_image             = "${module.ecr.repository_urls["backend"]}:latest"
#       task_cpu               = 256
#       task_memory            = 512
#       desired_count          = 1
#       enable_service_connect = false
#       enable_load_balancer   = true
#       container_port         = 8080
#       host_port              = 8080
#       path_pattern           = "/backend"
#       health_check_path      = "/backend"
#     }
#   ]

#   depends_on = [module.ecr]
# }

# Working till now

module "rds" {
  source = "./modules/rds"

  name_prefix                  = "sujal-rds"
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                    = [for s in module.vpc.private_subnets : s.id]
  allowed_sg_ids                = [module.ecs_sg.sg_id]
  tags                          = var.tags

  db_identifier                 = "sujal-rds"
  db_name                       = "myappdb"
  db_username                   = "myadmin"
  # password                      = "StrongPassword123!"
  manage_master_user_password   = true

  db_engine                     = "postgres"
  db_engine_version             = "17.2"
  db_instance_class             = "db.t3.micro"
  allocated_storage             = 20
  storage_type                  = "gp2"
  multi_az                      = false
  publicly_accessible           = false
  port                          = 5432

  db_subnet_group_name          = "sujal-rds-subnet-group"
  parameter_group_name          = "sujal-rds-parameter-group"
  db_family                     = "postgres17"

  storage_encrypted             = true
  create_kms_key                = false
  kms_key_policy_file           = "policy.json"

  auto_minor_version_upgrade    = true
  backup_retention_period       = 7
  skip_final_snapshot           = true

  iam_auth_enabled              = true
  performance_insights_enabled  = false

  create_aurora                 = false
}
