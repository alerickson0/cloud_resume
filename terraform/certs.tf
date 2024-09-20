resource "aws_acm_certificate" "ssl_certificate" {
  domain_name               = var.site_name
  subject_alternative_names = ["www.${var.site_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.ssl_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.my_validation_record : record.fqdn]
}
