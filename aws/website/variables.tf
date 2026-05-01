variable "bucket_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "domain_name" {
  description = "Custom domain name for the CloudFront distribution (e.g. example.com)"
  type        = string
}

variable "certificate_arn" {
  description = "AWS ACM certificate ARN for the custom domain. Must be in us-east-1."
  type        = string
}

variable "error_document" {
  description = "Path to the error page object in S3, served via CloudFront custom error response"
  type        = string
  default     = "error.html"
}
