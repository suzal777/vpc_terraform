output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds_sg.id
}

output "db_subnet_group" {
  description = "RDS Subnet Group name"
  value       = aws_db_subnet_group.main.name
}

output "parameter_group_name" {
  description = "RDS Parameter Group name"
  value       = aws_db_parameter_group.main.name
}

output "kms_key_arn" {
  description = "KMS Key ARN used for RDS (if created)"
  value       = try(aws_kms_key.main[0].arn, null)
}

output "read_replica_id" {
  description = "Read replica ID (if created)"
  value       = try(aws_db_instance.replica[0].id, null)
}

output "aurora_cluster_id" {
  description = "Aurora cluster ID (if created)"
  value       = try(aws_rds_cluster.aurora[0].id, null)
}

output "aurora_endpoints" {
  description = "Aurora endpoints for instances"
  value       = try([for inst in aws_rds_cluster_instance.aurora_instance : inst.endpoint], null)
}
