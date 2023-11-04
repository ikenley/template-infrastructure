#------------------------------------------------------------------------------
# Cognito
#------------------------------------------------------------------------------

resource "aws_cognito_user_pool" "this" {
  name = local.id

  #domain = "auth.${var.domain_name}"

  mfa_configuration = "OPTIONAL"

  sms_configuration {
    external_id    = random_uuid.cognito_external_id.result
    sns_caller_arn = aws_iam_role.cognito.arn
    sns_region     = data.aws_region.current.name
  }

  software_token_mfa_configuration {
    enabled = true
  }

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection      = "ACTIVE"

  email_configuration {
    email_sending_account = "DEVELOPER"
    from_email_address    = var.ses_email_address
    source_arn            = data.aws_ses_email_identity.ses_email_address.arn
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = local.tags
}

resource "random_uuid" "cognito_external_id" {}

resource "aws_iam_role" "cognito" {
  name = "${local.id}-cognito"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cognito-idp.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "sts:ExternalId" : random_uuid.cognito_external_id.result
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "cognito" {
  name        = "${local.id}-cognito"
  path        = "/"
  description = "Cognito user pool policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:publish"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cognito" {
  role       = aws_iam_role.cognito.name
  policy_arn = aws_iam_policy.cognito.arn
}

#------------------------------------------------------------------------------
# DNS
#------------------------------------------------------------------------------

locals {
  auth_domain = "auth.${var.domain_name}"
}

resource "aws_cognito_user_pool_domain" "this" {
  domain          = local.auth_domain
  certificate_arn = aws_acm_certificate.cognito.arn
  user_pool_id    = aws_cognito_user_pool.this.id

  depends_on = [aws_acm_certificate_validation.cognito_acm]
}

resource "aws_route53_record" "cognito" {
  name    = aws_cognito_user_pool_domain.this.domain
  type    = "A"
  zone_id = aws_route53_zone.public.zone_id
  alias {
    evaluate_target_health = false

    name    = aws_cognito_user_pool_domain.this.cloudfront_distribution
    zone_id = aws_cognito_user_pool_domain.this.cloudfront_distribution_zone_id
  }
}

resource "aws_acm_certificate" "cognito" {
  domain_name       = local.auth_domain
  validation_method = "DNS"
}

resource "aws_route53_record" "cognito_acm" {
  for_each = {
    for dvo in aws_acm_certificate.cognito.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.public.zone_id
}

resource "aws_acm_certificate_validation" "cognito_acm" {
  certificate_arn         = aws_acm_certificate.cognito.arn
  validation_record_fqdns = [for record in aws_route53_record.cognito_acm : record.fqdn]
}

#------------------------------------------------------------------------------
# client
#------------------------------------------------------------------------------

resource "aws_cognito_user_pool_client" "main" {
  name         = "main"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = true


  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  supported_identity_providers         = ["COGNITO", aws_cognito_identity_provider.google.provider_name]
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "phone"]
  allowed_oauth_flows_user_pool_client = true

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  callback_urls = [
    "http://localhost:8088/auth/api/login/callback",
    "https://auth-api.ikenley.com/callback"
  ]

  logout_urls = [
    "http://localhost:8088/auth/api/status"
  ]

  refresh_token_validity = 30
  access_token_validity  = 1
  id_token_validity      = 1
}

resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.this.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes = "email"
    client_id        = var.google_client_id
    client_secret    = var.google_client_secret
  }

  attribute_mapping = {
    email       = "email"
    username    = "sub"
    given_name  = "given_name"
    family_name = "family_name"
  }
}
