# #------------------------------------------------------------------------------
# # DNS and ALB
# #------------------------------------------------------------------------------

# #------------------------------------------------------------------------------
# # DNS record
# #------------------------------------------------------------------------------

# data "aws_route53_zone" "this" {
#   name         = "${var.parent_domain_name}."
#   private_zone = false
# }

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

# resource "aws_acm_certificate" "this" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"
# }

# resource "aws_route53_record" "validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.this.zone_id
# }

# resource "aws_acm_certificate_validation" "this" {
#   certificate_arn         = aws_acm_certificate.this.arn
#   validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
# }

# #------------------------------------------------------------------------------
# # ALB
# #------------------------------------------------------------------------------

# resource "aws_lb_listener_certificate" "example" {
#   listener_arn    = data.aws_lb_listener.prod.arn
#   certificate_arn = aws_acm_certificate.this.arn
# }

# resource "aws_lb_listener_rule" "this" {
#   listener_arn = data.aws_lb_listener.prod.arn
#   priority     = var.aws_lb_listener_rule_priority

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.this.arn
#   }

#   condition {
#     host_header {
#       values = [var.domain_name]
#     }
#   }
# }

# resource "aws_lambda_permission" "this" {
#   statement_id  = "AllowExecutionFromlb"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.this.function_name
#   principal     = "elasticloadbalancing.amazonaws.com"
#   source_arn    = aws_lb_target_group.this.arn
# }

# resource "aws_lb_target_group" "this" {
#   name        = local.id
#   target_type = "lambda"
# }

# resource "aws_lb_target_group_attachment" "this" {
#   target_group_arn = aws_lb_target_group.this.arn
#   target_id        = aws_lambda_function.this.arn
#   depends_on       = [aws_lambda_permission.this]
# }

#------------------------------------------------------------------------------
# Lambda security group
#------------------------------------------------------------------------------

resource "aws_security_group" "api_lambda" {
  name        = "${local.id}-lambda"
  description = "Allow inbound traffic from ALB and outbound to all"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
}

# resource "aws_security_group_rule" "api_lambda_ingress" {
#   security_group_id = aws_security_group.api_lambda.id
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"

#   source_security_group_id = data.aws_ssm_parameter.alb_public_sg_id.value
# }

resource "aws_security_group_rule" "api_lambda_egress_http" {
  security_group_id = aws_security_group.api_lambda.id
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "api_lambda_egress_https" {
  security_group_id = aws_security_group.api_lambda.id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "api_lambda_egress_pg" {
  security_group_id = aws_security_group.api_lambda.id
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [data.aws_ssm_parameter.vpc_cidr.value]
}