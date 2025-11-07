variable "domain_name" {
  description = "The domain name for the hosted zone."
  type        = string
}

variable "tags" {
  description = "Tags for hosted zone and records."
  type        = map(string)
  default     = {}
}

variable "records" {
  description = <<EOT
List of DNS records. Example:
[
  {
    name             = "app.example.com"
    type             = "A"
    ttl              = 300
    records          = ["1.2.3.4"]
    alias            = null
    set_identifier   = "app-east"
    weight           = 100
    failover_type    = null
    region           = null
    health_check_name = "app-health"
  }
]
EOT

  type = list(object({
    name              = string
    type              = string
    ttl               = optional(number)
    records           = optional(list(string))
    alias             = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool)
    }))
    set_identifier    = optional(string)
    weight            = optional(number)
    failover_type     = optional(string)
    region            = optional(string)
    health_check_name = optional(string)
  }))

  default = []
}

variable "health_checks" {
  description = <<EOT
Optional health checks to associate with records.
Example:
[
  {
    name = "app-health"
    fqdn = "app.example.com"
    port = 80
    type = "HTTP"
    resource_path = "/"
  }
]
EOT

  type = list(object({
    name              = string
    fqdn              = string
    port              = number
    type              = string
    resource_path     = optional(string)
    failure_threshold = optional(number)
    request_interval  = optional(number)
  }))

  default = []
}
