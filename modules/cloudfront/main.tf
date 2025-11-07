# Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "oac" {
  count = var.enable_oac ? 1 : 0

  name                              = var.oac_name
  description                       = var.oac_description
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  enabled             = var.enabled
  is_ipv6_enabled     = true
  comment             = var.comment
  price_class         = var.price_class
  default_root_object = var.default_root_object
  web_acl_id = var.web_acl_id

  # Origins (Supports OAC and Custom)
  dynamic "origin" {
    for_each = var.origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id

      # If OAC enabled and origin type is s3 → use OAC ID
      origin_access_control_id = (
        var.enable_oac && origin.value.origin_type == "s3" ?
        aws_cloudfront_origin_access_control.oac[0].id : null
      )

      dynamic "s3_origin_config" {
        for_each = (origin.value.origin_type == "s3" && !var.enable_oac) ? [1] : []
        content {
          origin_access_identity = lookup(origin.value, "origin_access_identity", null)
        }
      }

      dynamic "custom_origin_config" {
        for_each = origin.value.origin_type == "custom" ? [1] : []
        content {
          http_port              = lookup(origin.value, "http_port", 80)
          https_port             = lookup(origin.value, "https_port", 443)
          origin_protocol_policy = lookup(origin.value, "origin_protocol_policy", "https-only")
          origin_ssl_protocols   = lookup(origin.value, "origin_ssl_protocols", ["TLSv1.2"])
        }
      }
    }
  }

  # Default Cache Behavior
  default_cache_behavior {
    allowed_methods  = var.default_cache_behavior.allowed_methods
    cached_methods   = var.default_cache_behavior.cached_methods
    target_origin_id = var.default_cache_behavior.target_origin_id

    forwarded_values {
      query_string = var.default_cache_behavior.forwarded_values.query_string

      cookies {
        forward = var.default_cache_behavior.forwarded_values.cookies.forward
      }
    }

    viewer_protocol_policy = var.default_cache_behavior.viewer_protocol_policy
    min_ttl                = var.default_cache_behavior.min_ttl
    default_ttl            = var.default_cache_behavior.default_ttl
    max_ttl                = var.default_cache_behavior.max_ttl
  }

  # Additional Cache Behaviors (optional)
  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      target_origin_id = ordered_cache_behavior.value.target_origin_id
      allowed_methods  = ordered_cache_behavior.value.allowed_methods
      cached_methods   = ordered_cache_behavior.value.cached_methods

      forwarded_values {
        query_string = lookup(ordered_cache_behavior.value.forwarded_values, "query_string", false)
        cookies {
          forward = lookup(ordered_cache_behavior.value.forwarded_values.cookies, "forward", "none")
        }
      }

      viewer_protocol_policy = lookup(ordered_cache_behavior.value, "viewer_protocol_policy", "redirect-to-https")
      min_ttl                = lookup(ordered_cache_behavior.value, "min_ttl", 0)
      default_ttl            = lookup(ordered_cache_behavior.value, "default_ttl", 3600)
      max_ttl                = lookup(ordered_cache_behavior.value, "max_ttl", 86400)
    }
  }

  # Viewer Certificate
  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
  }

  # # Logging
  # logging_config {
  #   include_cookies = var.logging.include_cookies
  #   bucket          = var.logging.bucket
  #   prefix          = var.logging.prefix
  # }

  # Restrictions
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction.type
      locations        = var.geo_restriction.locations
    }
  }

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}
