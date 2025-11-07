# Route 53 Hosted Zone
resource "aws_route53_zone" "route53_zone" {
  name = var.domain_name
  tags = var.tags
}

# Health Checks (optional)
resource "aws_route53_health_check" "route53_health_check" {
  for_each = { for h in var.health_checks : h.name => h }

  fqdn              = each.value.fqdn
  port              = each.value.port
  type              = each.value.type
  resource_path     = lookup(each.value, "resource_path", null)
  failure_threshold = lookup(each.value, "failure_threshold", 3)
  request_interval  = lookup(each.value, "request_interval", 30)
  tags              = var.tags
}

# Dynamic DNS Records
resource "aws_route53_record" "records" {
  for_each = { for r in var.records : r.name => r }

  zone_id = aws_route53_zone.route53_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = lookup(each.value, "ttl", 300)

  # Basic records
  records = lookup(each.value, "records", null)

  # Alias support
  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = lookup(alias.value, "evaluate_target_health", false)
    }
  }

  # Routing policy (optional)
  set_identifier = lookup(each.value, "set_identifier", null)
  health_check_id = lookup(each.value, "health_check_name", null) != null ? aws_route53_health_check.route53_health_check[each.value.health_check_name].id : null

  weighted_routing_policy {
    weight = lookup(each.value, "weight", null)
  }

  failover_routing_policy {
    type = lookup(each.value, "failover_type", null)
  }

  latency_routing_policy {
    region = lookup(each.value, "region", null)
  }
}
