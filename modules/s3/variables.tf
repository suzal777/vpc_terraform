# Basic Bucket Settings
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "acl" {
  description = "Canned ACL for the bucket"
  type        = string
  default     = "private"
}

variable "tags" {
  description = "Tags for the bucket"
  type        = map(string)
  default     = {}
}

# Versioning
variable "versioning_enabled" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = true
}

# Encryption
variable "sse_rules" {
  description = "List of encryption rules for the S3 bucket"
  type = list(object({
    sse_algorithm     = string
    kms_master_key_id = optional(string)
  }))
  default = [
    {
      sse_algorithm = "AES256"
    }
  ]
}

# Lifecycle Rules
variable "lifecycle_rules" {
  description = "List of lifecycle management rules for the S3 bucket"
  type = list(object({
    id       = string
    status   = string
    prefix   = optional(string)
    transition = optional(object({
      days          = number
      storage_class = string
    }))
    expiration = optional(object({
      days = number
    }))
  }))

  default = []
}

variable "enable_lifecycle_rules" {
  type     = bool
  default  = false
}

# Bucket Policy
variable "bucket_policy" {
  description = "Bucket policy JSON string"
  type        = string
  default     = ""
}

# Public Access Block
variable "block_public_acls" {
  description = "Block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public buckets"
  type        = bool
  default     = true
}

# Optional Static Website Hosting
variable "enable_website" {
  description = "Enable static website hosting"
  type        = bool
  default     = false
}

variable "website_index_document" {
  description = "Index document for website (e.g., index.html)"
  type        = string
  default     = "index.html"
}

variable "website_error_document" {
  description = "Error document for website (e.g., error.html)"
  type        = string
  default     = "error.html"
}

variable "attach_cloudfront_policy" {
  description = "Attach a bucket policy allowing CloudFront OAC access"
  type        = bool
  default     = false
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN to grant access to the S3 bucket"
  type        = string
  default     = ""
}
