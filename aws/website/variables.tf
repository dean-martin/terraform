variable "bucket_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "domain_name" {
  description = "Set "
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "AWS ACM Certification ARN, passing this creates a CloudFront distribution. Default null."
  type        = string
  default     = null
}

variable "create_bucket" {
  description = "Create the S3 bucket and website configuration. Default true."
  type        = bool
  default     = true
}

variable "error_document" {
  description = "S3 website error document"
  type = string
  default = "error.html"
}
