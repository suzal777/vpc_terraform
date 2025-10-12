# KMS Key (Optional, for encryption)
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "main" {
  count = var.create_kms_key ? 1 : 0

  description             = var.kms_key_description
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_deletion_window_in_days

  # Inline JSON policy
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "rds-kms-policy"
    Statement = [
      # Allow the account root full access
      {
        Sid      = "EnableRootPermissions"
        Effect   = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      # Allow RDS to use the key
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
    Name = "${var.name_prefix}-rds-kms-key"
  })
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_sg_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-sg"
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = var.db_subnet_group_name
  subnet_ids  = var.subnet_ids
  description = "RDS Subnet Group"

  tags = merge(var.tags, {
    Name = var.db_subnet_group_name
  })
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  name        = var.parameter_group_name
  family      = var.db_family
  description = "RDS Parameter Group"

  tags = merge(var.tags, {
    Name = var.parameter_group_name
  })
}

# Primary RDS Instance
resource "aws_db_instance" "main" {
  identifier                 = var.db_identifier
  db_name                    = var.db_name
  engine                     = var.db_engine
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  storage_type               = var.storage_type
  allocated_storage          = var.allocated_storage
  multi_az                   = var.multi_az
  username                   = var.db_username
  manage_master_user_password = var.manage_master_user_password
  master_user_secret_kms_key_id = var.manage_master_user_password && var.create_kms_key ? aws_kms_key.main[0].id : null

  publicly_accessible        = var.publicly_accessible
  availability_zone          = var.availability_zone
  vpc_security_group_ids     = [aws_security_group.rds_sg.id]
  db_subnet_group_name       = aws_db_subnet_group.main.name
  parameter_group_name       = aws_db_parameter_group.main.name
  ca_cert_identifier         = var.ca_cert_identifier
  storage_encrypted          = var.storage_encrypted
  kms_key_id                 = var.storage_encrypted && var.create_kms_key ? aws_kms_key.main[0].arn : null
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  backup_retention_period    = var.backup_retention_period
  skip_final_snapshot        = var.skip_final_snapshot

  iam_database_authentication_enabled = var.iam_auth_enabled
  performance_insights_enabled           = var.performance_insights_enabled
  performance_insights_retention_period  = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  monitoring_interval = var.enable_monitoring ? 60 : 0
  monitoring_role_arn = var.monitoring_role_arn

  tags = merge(var.tags, {
    Name = var.db_identifier
  })
}

# Optional Read Replica
resource "aws_db_instance" "replica" {
  count               = var.create_read_replica ? 1 : 0
  replicate_source_db = aws_db_instance.main.id
  instance_class      = var.replica_instance_class
  publicly_accessible = false
  multi_az            = false

  tags = merge(var.tags, {
    Name = "${var.db_identifier}-replica"
  })
}

# Optional Aurora Cluster
resource "aws_rds_cluster" "aurora" {
  count                 = var.create_aurora ? 1 : 0
  cluster_identifier    = "${var.db_identifier}-cluster"
  engine                = "aurora-postgresql"
  engine_version        = var.db_engine_version
  master_username       = var.db_username
  master_password       = var.password
  database_name         = var.db_name
  backup_retention_period = var.backup_retention_period
  storage_encrypted     = true
  kms_key_id            = var.create_kms_key ? aws_kms_key.main[0].arn : null
  db_subnet_group_name  = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  deletion_protection   = var.deletion_protection
  port                  = var.port

  tags = merge(var.tags, {
    Name = "${var.db_identifier}-aurora"
  })
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  count               = var.create_aurora ? var.aurora_instance_count : 0
  identifier          = "${var.db_identifier}-instance-${count.index}"
  cluster_identifier  = aws_rds_cluster.aurora[0].id
  instance_class      = var.db_instance_class
  engine              = "aurora-postgresql"
  publicly_accessible = var.publicly_accessible

  tags = merge(var.tags, {
    Name = "${var.db_identifier}-aurora-instance-${count.index}"
  })
}
