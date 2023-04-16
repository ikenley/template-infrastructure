locals {
  core_output_prefix = "/${var.namespace}/${var.env}/core"
}

data "aws_ssm_parameter" "alb_public_arn" {
  name  = "${local.core_output_prefix}/alb_public_arn"
}

data "aws_ssm_parameter" "alb_public_sg_id" {
  name  = "${local.core_output_prefix}/alb_public_sg_id"
}