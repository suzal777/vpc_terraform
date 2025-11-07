# module "rds" {
#   source = "./modules/rds"

#   name_prefix = "sujal-rds"
#   vpc_id      = module.vpc.vpc_id
#   subnet_ids  = [for s in module.vpc.private_subnets : s.id]

#   # Deployment type options:
#   # "single-az-instance", "multi-az-instance", "multi-az-db-cluster"
#   deployment_type = "multi-az-db-cluster"

#   # DB Settings
#   database_name  = "portfolio_db"
#   engine_type    = "postgres"
#   engine_version = "17.4"         # Must use 17.4 for multi az db cluster
#   instance_class = "db.m5d.large" # Only use db.m5d.large for multi az db cluster else db.t3.medium
#   allocated_storage = 20

#   # allowed_sg = module.ecs.ecs_sg_id

#   master_username = "myadmin"
#   master_password = "password!123"

#   # Parameter group families
#   db_parameter_group_family          = "postgres17"
#   db_cluster_parameter_group_family  = "postgres17"

#   # Optional tuning
#   performance_insights_enabled          = true
#   performance_insights_retention_period = 7
#   iam_database_authentication           = false
#   create_kms_key                        = true
#   storage_encrypted                     = true
#   publicly_accessible                   = false

#   tags = var.tags
# }