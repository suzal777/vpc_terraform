output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cloudfront_distribution.domain_name
}

output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.cloudfront_distribution.id
}

output "oac_id" {
  description = "Origin Access Control ID"
  value       = try(aws_cloudfront_origin_access_control.oac[0].id, null)
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cloudfront_distribution.arn
}