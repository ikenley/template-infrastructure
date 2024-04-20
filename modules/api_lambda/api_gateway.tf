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
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal = "apigateway.amazonaws.com"

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

data "aws_route53_zone" "this" {
  name         = "${var.parent_domain_name}."
  private_zone = false
}

resource "aws_apigatewayv2_api_mapping" "example" {
  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.api_gateway.id
  stage       = aws_apigatewayv2_stage.default.id
}

resource "aws_apigatewayv2_domain_name" "api_gateway" {
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api_gateway.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [ aws_acm_certificate_validation.api_gateway ]
}

resource "aws_route53_record" "api_gateway" {
  name    = aws_apigatewayv2_domain_name.api_gateway.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.this.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.api_gateway.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_gateway.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# resource "aws_route53_record" "this" {
#   zone_id         = data.aws_route53_zone.this.zone_id
#   name            = var.domain_name
#   allow_overwrite = true
#   type            = "A"

#   alias {
#     name                   = data.aws_lb.this.dns_name
#     zone_id                = data.aws_lb.this.zone_id
#     evaluate_target_health = false
#   }
# }

resource "aws_acm_certificate" "api_gateway" {
  domain_name       = var.domain_name
  validation_method = "DNS"
}

resource "aws_route53_record" "validation_api_gateway" {
  for_each = {
    for dvo in aws_acm_certificate.api_gateway.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "api_gateway" {
  certificate_arn         = aws_acm_certificate.api_gateway.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_api_gateway : record.fqdn]
}



# #------------------------------------------------------------------------------
# # Lambda security group
# #------------------------------------------------------------------------------

# resource "aws_security_group" "api_lambda" {
#   name        = "${local.id}-lambda"
#   description = "Allow inbound traffic from ALB and outbound to all"
#   vpc_id      = data.aws_ssm_parameter.vpc_id.value
# }

# resource "aws_security_group_rule" "api_lambda_ingress" {
#   security_group_id = aws_security_group.api_lambda.id
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"

#   source_security_group_id = data.aws_ssm_parameter.alb_public_sg_id.value
# }

# resource "aws_security_group_rule" "api_lambda_egress_http" {
#   security_group_id = aws_security_group.api_lambda.id
#   type              = "egress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "api_lambda_egress_https" {
#   security_group_id = aws_security_group.api_lambda.id
#   type              = "egress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "api_lambda_egress_pg" {
#   security_group_id = aws_security_group.api_lambda.id
#   type              = "egress"
#   from_port         = 5432
#   to_port           = 5432
#   protocol          = "tcp"
#   cidr_blocks       = [data.aws_ssm_parameter.vpc_cidr.value]
# }
