variable "scope" {
  description = "Scope of the WAF (CLOUDFRONT or REGIONAL)"
  type        = string
  default     = "CLOUDFRONT"
}

variable "web_acl_name" {
  default = "my-cloudfront-waf"
}

variable "web_acl_description" {
  default = "Managed Web ACL with custom rules"
}

variable "default_action" {
  description = "Default action for unmatched requests (allow/block)"
  type        = string
  default     = "allow"
}

variable "rules" {
  description = "Managed rule groups to include in Web ACL"
  type = list(object({
    name              = string
    priority          = number
    action            = string
    managed_rule_name = string
    vendor_name       = string
  }))

  default = [
    {
      name              = "AWS-AWSManagedRulesCommonRuleSet"
      priority          = 1
      action            = "count"
      managed_rule_name = "AWSManagedRulesCommonRuleSet"
      vendor_name       = "AWS"
    }
  ]
}

variable "enable_logging" {
  description = "Enable WAF logging"
  type        = bool
  default     = false
}

variable "log_destination_arn" {
  description = "Destination ARN for logging (e.g., Kinesis Firehose)"
  type        = string
  default     = ""
}

variable "limit" {
  type = number
  default = 10
}

variable "aggregate_key_type" {
  type = string
  default = "IP"
}

variable "tags" {
  description = "Tags for WAF"
  type        = map(string)
  default     = {}
}