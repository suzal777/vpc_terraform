variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS and SG will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "allowed_sg_ids" {
  description = "List of Security Group IDs allowed to connect to RDS"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Master username"
  type        = string
}

variable "manage_master_user_password" {
  description = "Let AWS manage the master user password"
  type        = bool
  default     = true
}

variable "db_engine" {
  description = "RDS engine (postgres, mysql, aurora-postgresql, etc.)"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "17.2"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "replica_instance_class" {
  description = "Instance class for read replica"
  type        = string
  default     = "db.t3.micro"
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp2"
}

variable "allocated_storage" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Whether the RDS instance should have a public IP"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Availability zone for RDS"
  type        = string
  default     = null
}

variable "db_subnet_group_name" {
  description = "Name for the DB Subnet Group"
  type        = string
}

variable "parameter_group_name" {
  description = "Name for DB Parameter Group"
  type        = string
}

variable "db_family" {
  description = "DB parameter group family (postgres17, mysql8.0, etc.)"
  type        = string
  default     = "postgres17"
}

variable "storage_encrypted" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "create_kms_key" {
  description = "Create a new KMS key for RDS"
  type        = bool
  default     = true
}

variable "kms_key_policy_file" {
  description = "Path to the KMS key policy JSON file"
  type        = string
  default     = "policy.json"
}

variable "kms_key_description" {
  description = "KMS key description"
  type        = string
  default     = "KMS key for RDS encryption"
}

variable "kms_deletion_window_in_days" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 20
}

variable "auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrade"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on RDS deletion"
  type        = bool
  default     = true
}

variable "ca_cert_identifier" {
  description = "RDS CA certificate identifier"
  type        = string
  default     = "rds-ca-rsa2048-g1"
}

variable "iam_auth_enabled" {
  description = "Enable IAM-based authentication"
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Retention period for Performance Insights (days)"
  type        = number
  default     = 7
}

variable "enable_monitoring" {
  description = "Enable Enhanced Monitoring"
  type        = bool
  default     = false
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for Enhanced Monitoring"
  type        = string
  default     = null
}

variable "create_read_replica" {
  description = "Create a read replica"
  type        = bool
  default     = false
}

variable "create_aurora" {
  description = "Create Aurora cluster instead of standalone RDS"
  type        = bool
  default     = false
}

variable "aurora_instance_count" {
  description = "Number of instances in Aurora cluster"
  type        = number
  default     = 2
}

variable "deletion_protection" {
  description = "Enable deletion protection for Aurora cluster"
  type        = bool
  default     = false
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "password" {
  description = "Master password for Aurora (only for Aurora mode)"
  type        = string
  default     = null
}
