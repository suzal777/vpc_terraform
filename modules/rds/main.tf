# Locals for Deployment Logic
locals {
  is_single_az_instance  = var.deployment_type == "single-az-instance"
  is_multi_az_instance   = var.deployment_type == "multi-az-instance"
  is_multi_az_db_cluster = var.deployment_type == "multi-az-db-cluster"
}

# Data
data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_caller_identity" "current" {}

# KMS Key for Encryption
resource "aws_kms_key" "rds_key" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for RDS encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  # Inline policy with root and RDS permissions
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "rds-kms-policy"
    Statement = [
      {
        Sid      = "EnableRootPermissions"
        Effect   = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid      = "AllowRDSUse"
        Effect   = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-kms-key"
  })
}

resource "aws_kms_alias" "rds_key_alias" {
  count         = var.create_kms_key ? 1 : 0
  name          = "alias/${var.name_prefix}-rds-key"
  target_key_id = aws_kms_key.rds_key[0].id
}

# Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${var.name_prefix}-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "RDS Subnet Group"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-subnet-group"
  })
}

# Parameter Groups
resource "aws_db_parameter_group" "db_params" {
  name_prefix = "${var.name_prefix}-db-pg-"
  family      = var.db_parameter_group_family
  description = "RDS DB Parameter Group"

  dynamic "parameter" {
    for_each = var.additional_db_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-parameter-group"
  })
}

resource "aws_rds_cluster_parameter_group" "cluster_params" {
  count       = local.is_multi_az_db_cluster ? 1 : 0
  name_prefix = "${var.name_prefix}-cluster-pg-"
  family      = var.db_cluster_parameter_group_family
  description = "RDS Cluster Parameter Group"

  dynamic "parameter" {
    for_each = var.additional_cluster_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cluster-parameter-group"
  })
}

# Standard RDS Instance (Single-AZ or Multi-AZ)
resource "aws_db_instance" "instance" {
  count = local.is_single_az_instance || local.is_multi_az_instance ? 1 : 0

  identifier                 = var.name_prefix
  db_name                    = var.database_name
  engine                     = var.engine_type
  engine_version             = var.engine_version
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  storage_type               = var.storage_type
  multi_az                   = local.is_multi_az_instance
  publicly_accessible        = var.publicly_accessible
  vpc_security_group_ids     = [aws_security_group.rds_sg.id]
  db_subnet_group_name       = aws_db_subnet_group.main.name
  parameter_group_name       = aws_db_parameter_group.db_params.name
  username                   = var.master_username
  password                   = var.master_password
  storage_encrypted          = var.storage_encrypted
  kms_key_id                 = var.storage_encrypted && var.create_kms_key ? aws_kms_key.rds_key[0].arn : null
  backup_retention_period    = var.backup_retention_period
  skip_final_snapshot        = var.skip_final_snapshot
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled && var.create_kms_key ? aws_kms_key.rds_key[0].arn : null

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-instance"
  })
}

# Multi-AZ Cluster (Aurora or Native)
resource "aws_rds_cluster" "multi_az_cluster" {
  count = local.is_multi_az_db_cluster ? 1 : 0

  cluster_identifier              = "${var.name_prefix}-cluster"
  database_name                   = var.database_name
  db_cluster_instance_class       = var.instance_class
  master_username                 = var.master_username
  master_password                 = var.master_password
  engine                          = var.engine_type
  engine_version                  = var.engine_version
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.rds_sg.id]
  storage_encrypted               = true
  kms_key_id                      = var.create_kms_key ? aws_kms_key.rds_key[0].arn : null
  skip_final_snapshot             = var.skip_final_snapshot
  backup_retention_period         = var.backup_retention_period
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_params[0].name
  apply_immediately               = var.apply_immediately
  # Only set allocated_storage for non-Aurora engines
  allocated_storage = contains(["aurora", "aurora-mysql", "aurora-postgresql"], var.engine_type) ? null : var.allocated_storage
  storage_type                    = var.storage_type

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled && var.create_kms_key ? aws_kms_key.rds_key[0].arn : null

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-multi-az-cluster"
  })
}

resource "aws_rds_cluster_instance" "multi_az_cluster_instances" {
  count              = local.is_multi_az_db_cluster ? var.db_cluster_size : 0
  cluster_identifier = aws_rds_cluster.multi_az_cluster[0].id
  identifier         = "${var.name_prefix}-instance-${count.index}"
  instance_class     = var.instance_class
  engine             = var.engine_type

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled && var.create_kms_key ? aws_kms_key.rds_key[0].arn : null

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cluster-instance-${count.index}"
  })
}