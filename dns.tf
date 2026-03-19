locals {
  managed_certificate_enabled = var.acm_certificate_arn == null
  tls_certificate_arn         = local.managed_certificate_enabled ? aws_acm_certificate_validation.alb[0].certificate_arn : var.acm_certificate_arn
}

resource "aws_acm_certificate" "alb" {
  count = local.managed_certificate_enabled ? 1 : 0

  domain_name               = var.acm_domain_name
  subject_alternative_names = var.acm_subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Terraform = "true"
    Project   = var.project_name
    Role      = "acm"
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = local.managed_certificate_enabled ? {
    for dvo in aws_acm_certificate.alb[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "alb" {
  count = local.managed_certificate_enabled ? 1 : 0

  certificate_arn         = aws_acm_certificate.alb[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

resource "aws_route53_record" "alb_alias" {
  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}