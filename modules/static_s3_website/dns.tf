# Create alternate domain name and DNS record

data "aws_route53_zone" "this" {
  name         = "${var.parent_domain_name}."
  private_zone = false
}

resource "aws_route53_record" "static" {
  zone_id         = data.aws_route53_zone.this.zone_id
  name            = var.domain_name
  allow_overwrite = true
  type            = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

