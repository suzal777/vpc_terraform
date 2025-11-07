output "rds_instance_id" {
  description = "The RDS instance identifier"
  value       = try(aws_db_instance.instance[0].id, null)
}

output "rds_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = try(aws_db_instance.instance[0].endpoint, null)
}

output "rds_instance_arn" {
  description = "ARN of the RDS instance"
  value       = try(aws_db_instance.instance[0].arn, null)
}

output "rds_cluster_id" {
  description = "The RDS cluster identifier"
  value       = try(aws_rds_cluster.multi_az_cluster[0].id, null)
}

output "rds_cluster_endpoint" {
  description = "RDS cluster endpoint"
  value       = try(aws_rds_cluster.multi_az_cluster[0].endpoint, null)
}

output "rds_security_group_id" {
  description = "The security group ID associated with the RDS"
  value       = aws_security_group.rds_sg.id
}

output "rds_kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = try(aws_kms_key.rds_key[0].arn, null)
}
