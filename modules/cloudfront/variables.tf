variable "name" {
  description = "Name tag for CloudFront distribution"
  type        = string
  default     = "my-cloudfront-distribution"
}

variable "enabled" {
  description = "Enable or disable CloudFront distribution"
  type        = bool
  default     = true
}

variable "comment" {
  description = "Comment for CloudFront distribution"
  type        = string
  default     = "Managed by Terraform"
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "default_root_object" {
  description = "Default root object"
  type        = string
  default     = "index.html"
}

variable "origins" {
  description = "Map of origin configurations"
  type = map(object({
    domain_name            = string
    origin_id              = string
    origin_type            = string # 's3' or 'custom'
    origin_access_identity = optional(string)
    http_port              = optional(number)
    https_port             = optional(number)
    origin_protocol_policy = optional(string)
    origin_ssl_protocols   = optional(list(string))
  }))
  default = {
    s3_origin = {
      domain_name            = "mybucket.s3.amazonaws.com"
      origin_id              = "s3-origin"
      origin_type            = "s3"
      origin_access_identity = null
    }
  }
}

variable "enable_oac" {
  description = "Enable Origin Access Control (OAC) for S3 origin"
  type        = bool
  default     = true
}

variable "oac_name" {
  description = "Name of Origin Access Control"
  type        = string
  default     = "my-oac"
}

variable "oac_description" {
  description = "Description for Origin Access Control"
  type        = string
  default     = "CloudFront OAC for secure S3 access"
}

variable "default_cache_behavior" {
  description = "Default cache behavior configuration"
  type = object({
    target_origin_id = string
    allowed_methods  = list(string)
    cached_methods   = list(string)
    forwarded_values = object({
      query_string = bool
      cookies = object({
        forward = string
      })
    })
    viewer_protocol_policy = string
    min_ttl                = number
    default_ttl            = number
    max_ttl                = number
  })
  default = {
    target_origin_id = "s3-origin"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    forwarded_values = {
      query_string = false
      cookies = {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
}

variable "ordered_cache_behaviors" {
  description = "Optional ordered cache behaviors"
  type = list(object({
    path_pattern     = string
    target_origin_id = string
    allowed_methods  = list(string)
    cached_methods   = list(string)
    forwarded_values = object({
      query_string = bool
      cookies = object({
        forward = string
      })
    })
    viewer_protocol_policy = optional(string)
    min_ttl                = optional(number)
    default_ttl            = optional(number)
    max_ttl                = optional(number)
  }))
  default = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

variable "logging" {
  description = "CloudFront logging configuration"
  type = object({
    include_cookies = bool
    bucket          = string
    prefix          = string
  })
  default = {
    include_cookies = false
    bucket          = "my-logs-bucket.s3.amazonaws.com"
    prefix          = "cloudfront-logs/"
  }
}

variable "geo_restriction" {
  description = "Geo restriction settings"
  type = object({
    type       = string
    locations  = list(string)
  })
  default = {
    type      = "none"
    locations = []
  }
}

variable "tags" {
  description = "Tags for CloudFront distribution"
  type        = map(string)
  default     = {}
}

variable "web_acl_id" {
  type = string
}