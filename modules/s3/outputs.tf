output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.s3_bucket.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.s3_bucket.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name"
  value       = aws_s3_bucket.s3_bucket.bucket_domain_name
}

output "website_endpoint" {
  description = "Website endpoint (if enabled)"
  value       = var.enable_website ? aws_s3_bucket_website_configuration.s3_bucket_website_configuration[0].website_endpoint : ""
}
