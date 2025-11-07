provider "aws" {
  region = var.region
}

# module "vpc" {
#   source             = "./modules/vpc"
#   name               = var.vpc_name
#   cidr_block         = var.vpc_cidr
#   tags               = var.tags
#   subnets            = var.subnets
#   create_nat         = var.create_nat
#   create_nat_instance = var.create_nat_instance
# }

# module "s3_bucket" {
#   source = "./modules/s3"

#   bucket_name  = "sujals-bucket-777"
#   versioning_enabled = true

#   tags = var.tags

#   # lifecycle_rules = [
#   #   {
#   #     id       = "delete-raw"
#   #     status   = "Enabled"
#   #     prefix   = "raw/"
#   #     expiration = { days = 30 }
#   #   },
#   #   {
#   #     id       = "delete-rejects"
#   #     status   = "Enabled"
#   #     prefix   = "rejects/"
#   #     expiration = { days = 30 }
#   #   }
#   # ]

#   # bucket_policy = jsonencode({
#   #   Version = "2012-10-17",
#   #   Statement = [
#   #     {
#   #       Effect = "Allow",
#   #       Principal = "*",
#   #       Action = "s3:GetObject",
#   #       Resource = "arn:aws:s3:::sujals-bucket-777/*"
#   #     }
#   #   ]
#   # })

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true

#   enable_website          = true
#   attach_cloudfront_policy = true
#   enable_lifecycle_rules  = false
#   cloudfront_distribution_arn = module.cloudfront.distribution_arn
# }

# module "cloudfront" {
#   source = "./modules/cloudfront"

#   name    = "sujal-cdn"
#   comment = "CloudFront for S3 bucket"
#   web_acl_id = module.waf.web_acl_arn    # to enable waf
#   # web_acl_id = null                        # to disable waf

#   origins = {
#     s3_origin = {
#       domain_name = module.s3_bucket.bucket_domain_name   # dynamic reference
#       origin_id   = "s3-origin"
#       origin_type = "s3"
#     }
#   }

#   enable_oac          = true
#   oac_name            = "sujal-oac"
#   # acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcd-efgh-ijkl"
#   price_class         = "PriceClass_100"

#   tags = var.tags
# }



# module "waf" {
#   source = "./modules/waf"

#   web_acl_name       = "sujal-cloudfront-waf"
#   scope              = "CLOUDFRONT"
#   default_action     = "allow"

#   enable_logging     = false
#   # log_destination_arn = "arn:aws:firehose:us-east-1:123456789012:deliverystream/my-waf-logs"

#   rules = [
#     {
#       name              = "AWS-AWSManagedRulesCommonRuleSet"
#       priority          = 1
#       action            = "count"
#       managed_rule_name = "AWSManagedRulesCommonRuleSet"
#       vendor_name       = "AWS"
#     },
#     {
#       name              = "AWS-AWSManagedRulesSQLiRuleSet"
#       priority          = 2
#       action            = "count"
#       managed_rule_name = "AWSManagedRulesSQLiRuleSet"
#       vendor_name       = "AWS"
#     }
#   ]

#   tags = var.tags
# }




