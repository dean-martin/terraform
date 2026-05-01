output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution._.domain_name
  description = "The domain name of the CloudFront distribution."
}

output "cloudfront_id" {
  value       = aws_cloudfront_distribution._.id
  description = "CloudFront distribution ID"
}

output "cloudfront_arn" {
  value       = aws_cloudfront_distribution._.arn
  description = "CloudFront distribution ARN"
}

output "s3_bucket" {
  value       = aws_s3_bucket._.bucket
  description = "S3 bucket name for the website"
}
