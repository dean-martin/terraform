#!/usr/bin/env bash
# @see: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html
aws cloudfront create-invalidation --distribution-id $(terraform output -raw cloudfront_id) --paths "/*"
