# ------------------------------------------------------------------------------
# api_gateway.tf
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "certificate_arn" {
  name  = "${local.output_prefix}/certificate_arn"
  type  = "String"
  value = aws_acm_certificate.this.arn
}

output "certificate_arn" {
  value = aws_acm_certificate.this.arn
}

