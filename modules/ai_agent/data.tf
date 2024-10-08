locals {
  core_output_prefix = "/${var.namespace}/${var.env}/core"
}

# # Core management
# data "aws_ssm_parameter" "event_bus_arn" {
#   name  = "${local.core_output_prefix}/event_bus_arn"
# }
# data "aws_ssm_parameter" "event_bus_name" {
#   name  = "${local.core_output_prefix}/event_bus_name"
# }
# data "aws_ssm_parameter" "ses_email_address" {
#   name  = "${local.core_output_prefix}/ses_email_address"
# }
# data "aws_ssm_parameter" "ses_email_arn" {
#   name  = "${local.core_output_prefix}/ses_email_arn"
# }

# Network
locals {
  private_subnets  = split(",", nonsensitive(data.aws_ssm_parameter.private_subnets.value))
  database_subnets = split(",", nonsensitive(data.aws_ssm_parameter.database_subnets.value))
  azs              = split(",", nonsensitive(data.aws_ssm_parameter.azs.value))
}

data "aws_ssm_parameter" "vpc_id" {
  name = "${local.core_output_prefix}/vpc_id"
}

data "aws_ssm_parameter" "vpc_cidr" {
  name = "${local.core_output_prefix}/vpc_cidr"
}

data "aws_ssm_parameter" "private_subnets" {
  name = "${local.core_output_prefix}/private_subnets"
}
data "aws_ssm_parameter" "database_subnets" {
  name = "${local.core_output_prefix}/database_subnets"
}
data "aws_ssm_parameter" "azs" {
  name = "${local.core_output_prefix}/azs"
}


# Data environment
data "aws_ssm_parameter" "data_lake_s3_bucket_arn" {
  name = "${local.core_output_prefix}/data_lake_s3_bucket_arn"
}
data "aws_ssm_parameter" "data_lake_s3_bucket_name" {
  name = "${local.core_output_prefix}/data_lake_s3_bucket_name"
}
