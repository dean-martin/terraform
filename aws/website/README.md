# S3 Website with CloudFront for TLS

See scripts/ for some useful, well scripts.

### Example Module Usage
```hcl
variable "domain_name" {}
// AWS S3 Website
// Optional TLS with CloudFront Distribution
module "test_website" {
  source      = "./aws/website"
  domain_name = var.domain_name
  bucket_name = "${var.domain_name}mywebsite-zzzzz"

  # Setting this will create a CloudFront Distribution
  certificate_arn = module.acm_cert.certificate_arn
}

// Create AWS ACM Certificate.
// Verify via DNS in Terraform or manually in your registrar.
// Verification can take up to an hour, it's usually much faster.
module "acm_cert" {
  source      = "./aws/acm-certificate"
  domain_name = var.domain_name
}

# TODO: Consider moving DNS verification to the acm-certificate module.

// Cloudflare DNS Verification.
data "cloudflare_zones" "zones" { 
  name = var.domain_name
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
output "s3_website" {
  value       = "http://${module.test_website.s3_website}"
  description = "S3 Website URL"
}

output "cloudfront_domain" {
  value = "https://${module.test_website.cloudfront_domain_name}"
  description = "CloudFront Distribution URL"
}
```
