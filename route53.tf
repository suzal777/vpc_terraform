# module "route53" {
#   source = "./modules/route53"

#   domain_name = "example.com"

#   tags = var.tags

#   health_checks = [
#     {
#       name          = "app-health"
#       fqdn          = "app.example.com"
#       port          = 80
#       type          = "HTTP"
#       resource_path = "/"
#     }
#   ]

#   records = [
#     {
#       name              = "app.example.com"
#       type              = "A"
#       ttl               = 60
#       records           = ["1.2.3.4"]
#       alias             = null
#       set_identifier    = "east"
#       weight            = 100
#       failover_type     = null
#       region            = null
#       health_check_name = "app-health"
#     }
#   ]
# }
