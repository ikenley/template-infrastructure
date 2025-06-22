#------------------------------------------------------------------------------
# Creates an ACM SSL certificate
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  // Get the domain name without any special characters except '-'
  // Example "my-test.example.com" => "my-testexamplecom"
  domain_id = replace(var.domain_name, "/[^a-zA-Z\\-]/", "")

  id            = "${var.namespace}-${var.env}-${var.project_name}"
  output_prefix = "/${var.namespace}/${var.env}/${var.project_name}/acm-cert/${local.domain_id}"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    Namespace   = var.namespace
    is_prod     = var.is_prod
  })
}
