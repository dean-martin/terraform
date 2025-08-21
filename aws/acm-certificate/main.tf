variable "domain_name" {
  type = string
}

resource "aws_acm_certificate" "_" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

output "validation_records" {
  value = aws_acm_certificate._.domain_validation_options
}

# Output the DNS validation records to be added to the third-party registrar
output "validation_records_map" {
  # Using distinct() here because wildcard domains usually have the same "record_name"
  # value and cause errors.
  value = { for record in distinct([
    for record in aws_acm_certificate._.domain_validation_options : {
      name  = record.resource_record_name
      type  = record.resource_record_type
      value = record.resource_record_value
    }
    ]) : record.name => record
  }
  description = "DNS records to add to your third-party registrar for certificate validation."
}

output "certificate_arn" {
  value = aws_acm_certificate._.arn
}
