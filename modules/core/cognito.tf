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

  lambda_config {
    pre_sign_up = aws_lambda_function.pre_signup_trigger.arn
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

  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls

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

    attributes_url                = "https://people.googleapis.com/v1/people/me?personFields="
    attributes_url_add_attributes = "true"
    authorize_url                 = "https://accounts.google.com/o/oauth2/v2/auth"
    oidc_issuer                   = "https://accounts.google.com"
    token_request_method          = "POST"
    token_url                     = "https://www.googleapis.com/oauth2/v4/token"
  }

  attribute_mapping = {
    email       = "email"
    username    = "sub"
    given_name  = "given_name"
    family_name = "family_name"
  }
}

#------------------------------------------------------------------------------
# Pre sign-up Lambda trigger
# https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-pre-sign-up.html
#------------------------------------------------------------------------------

locals {
  pre_signup_trigger_id = "${local.id}-cognito-pre-signup-trigger"
}

resource "aws_lambda_function" "pre_signup_trigger" {
  function_name = local.pre_signup_trigger_id

  description = "Validate Cognito signup triggers"

  role = aws_iam_role.pre_signup_trigger.arn

  filename         = data.archive_file.pre_signup_trigger.output_path
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.external.lambda_hash.result.hash
  runtime          = "python3.13"

  environment {
    variables = {
      APP_ENV               = var.env
      INVITATION_TABLE_NAME = aws_dynamodb_table.pre_signup_trigger.name
    }
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.pre_signup_trigger.id]
  }
}

# Ensure consistent source code hash
data "external" "lambda_hash" {
  program = ["python3", "-c", "import hashlib,sys,json; print(json.dumps({'hash':hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest()}))", "${path.module}/lambda/pre_signup_trigger/src/lambda_function.py"]
}

data "archive_file" "pre_signup_trigger" {
  type        = "zip"
  source_file = "${path.module}/lambda/pre_signup_trigger/src/lambda_function.py"
  output_path = "${path.module}/lambda/pre_signup_trigger/src/lambda_function.zip"
}

resource "aws_iam_role" "pre_signup_trigger" {
  name = local.pre_signup_trigger_id

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "pre_signup_trigger" {
  role       = aws_iam_role.pre_signup_trigger.name
  policy_arn = aws_iam_policy.pre_signup_trigger.arn
}

resource "aws_iam_policy" "pre_signup_trigger" {
  name        = local.pre_signup_trigger_id
  path        = "/"
  description = "Lambda execution policy for ${local.pre_signup_trigger_id}"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowLogging",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowVpcAccess",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AccessTableAllIndexesOnBooks",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:ConditionCheckItem"
        ],
        "Resource" : [
          "${aws_dynamodb_table.pre_signup_trigger.arn}",
          "${aws_dynamodb_table.pre_signup_trigger.arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_lambda_permission" "pre_signup_trigger" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pre_signup_trigger.arn
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.this.arn
  depends_on    = [aws_lambda_function.pre_signup_trigger]
}

resource "aws_security_group" "pre_signup_trigger" {
  name        = local.pre_signup_trigger_id
  description = "Allow outbound to all"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "pre_signup_trigger" {
  security_group_id = aws_security_group.pre_signup_trigger.id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_dynamodb_table" "pre_signup_trigger" {
  name = local.pre_signup_trigger_id

  billing_mode = "PAY_PER_REQUEST"

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  hash_key  = "hash_key"
  range_key = "range_key"

  attribute {
    name = "hash_key"
    type = "S"
  }

  attribute {
    name = "range_key"
    type = "S"
  }

  replica {
    region_name = "us-west-2"
  }

  tags = merge(local.tags, {
    Name = local.pre_signup_trigger_id
  })
}
