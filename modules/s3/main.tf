# S3 Bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

# Versioning
resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encryption" {
  bucket = aws_s3_bucket.s3_bucket.id

  dynamic "rule" {
    for_each = var.sse_rules
    content {
      apply_server_side_encryption_by_default {
        sse_algorithm     = rule.value.sse_algorithm
        kms_master_key_id = lookup(rule.value, "kms_master_key_id", null)
      }
    }
  }
}


# Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle_configuration" {
  count  = var.enable_lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      filter {
        prefix = rule.value.prefix
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transition", null) != null ? [rule.value.transition] : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration", null) != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
    }
  }
}

# Secure Bucket Policy (auto applies if CloudFront OAC is enabled)
resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  count = var.attach_cloudfront_policy && var.cloudfront_distribution_arn != "" ? 1 : (
    var.bucket_policy != "" ? 1 : 0
  )

  bucket = aws_s3_bucket.s3_bucket.id

  policy = var.attach_cloudfront_policy && var.cloudfront_distribution_arn != "" ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.s3_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  }) : var.bucket_policy

  depends_on = [
    aws_s3_bucket_public_access_block.s3_bucket_public_access_block
  ]
}


# Public Access Block
resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Optional Static Website Hosting
resource "aws_s3_bucket_website_configuration" "s3_bucket_website_configuration" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id

  dynamic "index_document" {
    for_each = var.website_index_document != "" ? [1] : []
    content {
      suffix = var.website_index_document
    }
  }

  dynamic "error_document" {
    for_each = var.website_error_document != "" ? [1] : []
    content {
      key = var.website_error_document
    }
  }
}
