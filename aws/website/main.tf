# see: https://repost.aws/knowledge-center/cloudfront-serve-static-website
# see: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CNAMEs.html#alternate-domain-names-requirements
/*
 lol, this is amazing:
 - https://stackoverflow.com/questions/49082709/redirect-to-index-html-for-s3-subfolder
 - https://gist.github.com/zulhfreelancer/24f73015c5437281f3b98c3cb34ea225
 - https://stackoverflow.com/questions/31017105/how-do-you-set-a-default-root-object-for-subdirectories-for-a-statically-hosted

 "Official Answer" is to use a Lamba? For static hosting? no way
 asinine
 */
resource "aws_s3_bucket" "_" {
  bucket = var.bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "allow_public_acls" {
  bucket = aws_s3_bucket._.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "_" {
  bucket = aws_s3_bucket._.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "s3_website" {
  bucket = aws_s3_bucket._.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket._.arn,
          "${aws_s3_bucket._.arn}/*",
        ]
      },
    ]
  })
}

/*
# Disabled since we're going to use access S3 from CloudFront via S3 Website.
See stackoverflow links above for why.
# @see: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  count  = var.certificate_arn != null ? 1 : 0
  bucket = aws_s3_bucket._.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket._.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution._[0].arn
          }
        }
      },
    ]
  })
}
*/

locals {
  s3_origin_id = "s3_website_${var.domain_name}"
}

resource "aws_cloudfront_origin_access_control" "_" {
  count                             = var.certificate_arn != null ? 1 : 0
  name                              = "s3_website_${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "_" {
  count = var.certificate_arn != null ? 1 : 0
  origin {
    domain_name              = aws_s3_bucket._.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control._[0].id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "AWS S3 + CloudFront Website -- Managed by Terraform"
  default_root_object = "index.html"

  aliases = [var.domain_name, "www.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"] # Allow common read-only methods
    cached_methods   = ["GET", "HEAD"]            # Cache responses for GET and HEAD
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # TODO: consider other ordered_cache_behavior, might be useful for serving resume.PDF

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      # i guess this will prevent bots incurring extra cost
      locations = ["US", "CA", "GB", "DE", "JP"]
    }
  }

  # Attach the ACM certificate to the CloudFront distribution
  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn # Reference the ACM certificate ARN
    ssl_support_method       = "sni-only"          # Use SNI for cost efficiency
    minimum_protocol_version = "TLSv1.2_2021"      # Set a secure minimum protocol version
  }
}
