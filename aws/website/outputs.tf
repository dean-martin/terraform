output "cloudfront_domain_name" {
  value       = var.certificate_arn != null ? aws_cloudfront_distribution._[0].domain_name : "N/A"
  description = "The domain name of the CloudFront distribution."
}

output "cloudfront_id" {
  value       = var.certificate_arn != null ? aws_cloudfront_distribution._[0].id : "N/A"
  description = "CloudFront distribution ID"
}

output "s3_bucket" {
  value       = aws_s3_bucket._.bucket
  description = "S3 bucket name for the website"
}

output "s3_website" {
  value = aws_s3_bucket_website_configuration._.website_endpoint
}
