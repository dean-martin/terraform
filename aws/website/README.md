# S3 Website with CloudFront for TLS

See scripts/ for some useful, well scripts.

### Simple Example
```hcl
locals {
  domain = "example.com"
}
module "example_com" {
  source = "git::github.com/dean-martin/terraform//aws/website"
  domain_name = local.domain
  bucket_name = "${local.domain}-unique-key-123"

  certificate_arn = aws_acm_certificate.cert.arn
}

resource "aws_acm_certificate" "cert" {
  domain_name       = local.domain
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${local.domain}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Manually input validation records in your registrar.
output "validation_records" {
  value = aws_acm_certificate.cert.domain_validation_options
}

# Used in upload.sh script.
output "s3_bucket" {
  value = module.example_com.s3_bucket
}

# Used in invalidate-cache.sh script.
output "cloudfront_id" {
  value = module.example_com.cloudfront_id
}
```

### Automated Cloudflare Records
```hcl
locals {
  domain = "example.com"
}
// AWS S3 Website
// Optional TLS with CloudFront Distribution
module "test_website" {
  source      = "git::github.com/dean-martin/terraform//aws/website"
  domain_name = local.domain
  bucket_name = "${local.domain}-unique-key-123"

  # Setting this will create a CloudFront Distribution
  certificate_arn = module.acm_cert.certificate_arn
}

// Create AWS ACM Certificate.
// Verify via DNS in Terraform or manually in your registrar.
// Verification can take up to an hour, it's usually much faster.
module "acm_cert" {
  source      = "git::github.com/dean-martin/terraform//aws/acm-certificate"
  domain_name = local.domain
}

# TODO: Move DNS verification to the acm-certificate module.

// Cloudflare DNS Verification.
data "cloudflare_zones" "zones" { 
  name = local.domain
}
resource "cloudflare_dns_record" "cert_verification" {
  for_each = module.acm_cert.validation_records_map

  zone_id = data.cloudflare_zones.zones.result[0].id

  name    = each.value.name
  type    = each.value.type
  content = each.value.value
  comment = "AWS ACM Certificate Verification. Managed by Terraform."
  ttl     = 1 # Setting to 1 means "automatic"
  proxied = false
}

// Or manually enter them into your registrar.
output "dns_validation_records" {
  value       = module.acm_cert.validation_records
  description = "DNS records to add to your third-party registrar for certificate validation."
}


// Outputs
# Used in upload.sh script.
output "s3_bucket" {
  value = module.example_com.s3_bucket
}

# Used in invalidate-cache.sh script.
output "cloudfront_id" {
  value = module.example_com.cloudfront_id
}
```
