#------------------------------------------------------------------------------
# DNS and API Gateway
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# API Gateway
#------------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "this" {
  name          = local.id
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"

  target = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_integration" "this" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"

  payload_format_version = "2.0"
  connection_type        = "INTERNET"
  description            = "Invoke Lambda API service"
  integration_uri        = aws_lambda_function.this.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_deployment" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  description = "Default deployment"

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_integration.this),
      jsonencode(aws_apigatewayv2_route.default),
    ])))
  }

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# DNS record
#------------------------------------------------------------------------------

locals {
  acm_certificate_arn = var.create_acm_certificate ? module.acm_certificate[0].certificate_arn : var.acm_certificate_arn
}

resource "aws_apigatewayv2_api_mapping" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.api_gateway.id
  stage       = aws_apigatewayv2_stage.default.id
}

resource "aws_apigatewayv2_domain_name" "api_gateway" {
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = local.acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  ##depends_on = [aws_acm_certificate_validation.api_gateway]
}

# ACM certificate
data "aws_route53_zone" "this" {
  name         = "${var.parent_domain_name}."
  private_zone = false
}

module "acm_certificate" {
  count = var.create_acm_certificate ? 1 : 0

  source = "../acm_certificate"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = var.project_name

  domain_name      = var.domain_name
  route_53_zone_id = data.aws_route53_zone.this.zone_id

  tags = var.tags
}
