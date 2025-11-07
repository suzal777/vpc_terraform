# General Configuration
variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "deployment_type" {
  description = "Deployment type: single-az-instance | multi-az-instance | multi-az-db-cluster"
  type        = string
  default     = "single-az-instance"
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "port" {
  description = "Port on which RDS listens"
  type        = number
  default     = 5432
}

# variable "allowed_sg" {
#   description = "Allowed security group id for rds sg"
#   type = string
# }

# Database Configuration
variable "database_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "mydb"
}

variable "engine_type" {
  description = "Database engine type (e.g., mysql, postgres, aurora-postgresql)"
  type        = string
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
}

variable "instance_class" {
  description = "Instance class (e.g., db.t3.medium)"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Storage (in GB) for RDS instance"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "master_username" {
  description = "Master username for RDS"
  type        = string
}

variable "master_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

# Security & Encryption
variable "create_kms_key" {
  description = "Whether to create a dedicated KMS key for RDS encryption"
  type        = bool
  default     = true
}

variable "storage_encrypted" {
  description = "Enable storage encryption for RDS"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply modifications immediately (true) or during maintenance window"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on DB deletion"
  type        = bool
  default     = true
}

variable "publicly_accessible" {
  description = "If true, RDS is publicly accessible"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Auto minor version upgrades"
  type        = bool
  default     = true
}

# Performance Insights & IAM Auth
variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Retention period for Performance Insights data (7, 731)"
  type        = number
  default     = 7
}

variable "iam_database_authentication" {
  description = "Enable IAM authentication for RDS"
  type        = bool
  default     = false
}

# Parameter Groups
variable "db_parameter_group_family" {
  description = "DB parameter group family (e.g., postgres15)"
  type        = string
}

variable "db_cluster_parameter_group_family" {
  description = "Cluster parameter group family (for Multi-AZ DB clusters)"
  type        = string
  default     = "aurora-postgresql15"
}

variable "additional_db_parameters" {
  description = "Map of additional DB parameters"
  type        = map(string)
  default     = {}
}

variable "additional_cluster_parameters" {
  description = "Map of additional cluster parameters"
  type        = map(string)
  default     = {}
}

# Multi-AZ Cluster Settings
variable "db_cluster_size" {
  description = "Number of instances in the Multi-AZ DB cluster"
  type        = number
  default     = 2
}
