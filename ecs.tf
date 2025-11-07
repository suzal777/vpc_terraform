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

# ------------------------------------------------------------------ #

# module "ecs" {
#   source      = "./modules/ecs"

#   name        = "sujal"
#   region      = var.region
#   vpc_cidr    = var.vpc_cidr
#   vpc_id       = module.vpc.vpc_id
#   subnet_ids   = [for s in module.vpc.public_subnets : s.id]
#   private_subnet_ids   = [for s in module.vpc.private_subnets : s.id]
#   tags        = var.tags
#   launch_type = "EC2"  # "EC2" or "FARGATE"
#   enable_fargate_spot = true
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