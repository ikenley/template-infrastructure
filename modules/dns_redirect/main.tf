
# ------------------------------------------------------------------------------
# Creates the DNS record and S3 redirect bucket
# ------------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    is_prod     = var.is_prod
  })
}

data "aws_route53_zone" "this" {
  name = var.domain_name
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_s3_bucket.this.website_domain
    zone_id                = aws_s3_bucket.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket" "this" {
  bucket = var.domain_name

  acl    = "public-read"
  policy = data.aws_iam_policy_document.website_policy.json
  website {
    redirect_all_requests_to = var.redirect_url
  }

  tags = merge(local.tags, {})
}

data "aws_iam_policy_document" "website_policy" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    resources = [
      "arn:aws:s3:::${var.domain_name}/*"
    ]
  }
}
