locals {
  core_output_prefix = "/${var.namespace}/${var.env}/core"
}

# Network

data "aws_ssm_parameter" "alb_public_arn" {
  name  = "${local.core_output_prefix}/alb_public_arn"
}

data "aws_lb" "this" {
  arn  = data.aws_ssm_parameter.alb_public_arn.value
}

data "aws_lb_listener" "prod" {
  load_balancer_arn = data.aws_ssm_parameter.alb_public_arn.value
  port              = 443
}

data "aws_ssm_parameter" "alb_public_sg_id" {
  name  = "${local.core_output_prefix}/alb_public_sg_id"
}
