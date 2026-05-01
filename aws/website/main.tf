resource "aws_s3_bucket" "_" {
  bucket = var.bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "_" {
  bucket = aws_s3_bucket._.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "_" {
  name                              = "s3_website_${var.domain_name}"
  description                       = "OAC for ${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "_" {
  name    = "subdirectory_index_${replace(var.domain_name, ".", "_")}"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite bare directory URIs to index.html for ${var.domain_name}"
  publish = true

  code = <<-EOF
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      if (uri.endsWith('/')) {
        request.uri = uri + 'index.html';
        return request;
      }

      var lastSegment = uri.split('/').pop();
      if (lastSegment.indexOf('.') === -1) {
        request.uri = uri + '/index.html';
      }

      return request;
    }
  EOF
}

resource "aws_s3_bucket_policy" "_" {
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
            "AWS:SourceArn" = aws_cloudfront_distribution._.arn
          }
        }
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block._]
}

locals {
  s3_origin_id = "s3_website_${var.domain_name}"
}

resource "aws_cloudfront_distribution" "_" {
  origin {
    origin_id                = local.s3_origin_id
    domain_name              = aws_s3_bucket._.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control._.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "AWS S3 + CloudFront Website -- Managed by Terraform"
  default_root_object = "index.html"

  aliases = [var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function._.arn
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # S3 returns 403 (not 404) for missing objects when the bucket is private
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/${var.error_document}"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/${var.error_document}"
    error_caching_min_ttl = 10
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "JP"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
