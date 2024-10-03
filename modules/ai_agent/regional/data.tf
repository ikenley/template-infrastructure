locals {
  core_output_prefix = "/${var.namespace}/${var.env}/core"
}

# Network
# data "aws_subnet" "private_subnets" {
#   for_each = local.private_subnets
#   id       = each.value
# }

locals {
  private_subnets = toset(split(",", nonsensitive(data.aws_ssm_parameter.private_subnets.value)))
}

data "aws_ssm_parameter" "vpc_id" {
  name = "${local.core_output_prefix}/vpc_id"
}

data "aws_ssm_parameter" "private_subnets" {
  name = "${local.core_output_prefix}/private_subnets"
}

# Data environment
data "aws_ssm_parameter" "s3_knowledge_base_arn" {
  name = "${local.core_output_prefix}/s3_knowledge_base_arn"
}
data "aws_ssm_parameter" "s3_knowledge_base_name" {
  name = "${local.core_output_prefix}/s3_knowledge_base_name"
}
