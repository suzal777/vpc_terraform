output "zone_id" {
  description = "Hosted zone ID."
  value       = aws_route53_zone.route53_zone.zone_id
}

output "zone_name_servers" {
  description = "List of name servers."
  value       = aws_route53_zone.route53_zone.name_servers
}
