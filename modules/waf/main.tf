resource "aws_wafv2_web_acl" "web_acl" {
  name        = var.web_acl_name
  description = var.web_acl_description
  scope       = var.scope
  tags = var.tags

  # Default Action (allow or block)
  dynamic "default_action" {
    for_each = var.default_action == "allow" ? [1] : []
    content {
      allow {}
    }
  }

  dynamic "default_action" {
    for_each = var.default_action == "block" ? [1] : []
    content {
      block {}
    }
  }

  # Managed AWS Rule Groups
  dynamic "rule" {
    for_each = var.rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      # Override action: count or none
      dynamic "override_action" {
        for_each = rule.value.action == "count" ? [1] : []
        content {
          count {}
        }
      }

      dynamic "override_action" {
        for_each = rule.value.action == "none" ? [1] : []
        content {
          none {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.managed_rule_name
          vendor_name = rule.value.vendor_name
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  # Custom Rate-Based Rule (10 req/5min/IP)
  rule {
    name     = "limit-requests"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.limit
        aggregate_key_type = var.aggregate_key_type
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "limit-requests"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "my-web-acl"
    sampled_requests_enabled   = true
  }
}

# Optional Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "logging" {
  count = var.enable_logging ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.web_acl.arn
  log_destination_configs = [var.log_destination_arn]
}
