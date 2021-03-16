
data "aws_caller_identity" "current" {}

locals {
  tags = merge(var.tags, {
    Terraform = true
  })
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# DNS
data "aws_route53_zone" "this" {
  name         = "${var.domain_name}."
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${var.dns_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.alb.aws_lb_lb_dns_name
    zone_id                = module.alb.aws_lb_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "this" {
  domain_name       = "${var.dns_subdomain}.${var.domain_name}"
  validation_method = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "ssl_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
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

# ECS Fargate
# https://github.com/cn-terraform/terraform-aws-ecs-fargate

# Task Definition
# https://github.com/cn-terraform/terraform-aws-ecs-fargate-task-definition

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.name}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  container_definitions    = var.ecs_container_definitions
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  requires_compatibilities = ["FARGATE"]

  tags = local.tags
}

# ECS Service
# https://github.com/cn-terraform/terraform-aws-ecs-fargate-service

#------------------------------------------------------------------------------
# AWS LOAD BALANCER
#------------------------------------------------------------------------------
module "alb" {
  source  = "../ecs_alb"

  name_prefix = var.name
  vpc_id      = var.vpc_id

  # S3 Bucket
  block_s3_bucket_public_access = true

  # Application Load Balancer
  #internal                         = var.lb_internal
  #security_groups                  = var.lb_security_groups
  #drop_invalid_header_fields       = var.lb_drop_invalid_header_fields
  private_subnets                  = var.private_subnets
  public_subnets                   = var.public_subnets
  #idle_timeout                     = var.lb_idle_timeout
  #enable_deletion_protection       = var.lb_enable_deletion_protection
  #enable_cross_zone_load_balancing = var.lb_enable_cross_zone_load_balancing
  #enable_http2                     = var.lb_enable_http2
  #ip_address_type                  = var.lb_ip_address_type

  # Access Control to Application Load Balancer
  # TODO redirect to https
  #http_ports                    = var.lb_http_ports
  #http_ingress_cidr_blocks      = var.lb_http_ingress_cidr_blocks
  #http_ingress_prefix_list_ids  = var.lb_http_ingress_prefix_list_ids
  #https_ports                   = var.lb_https_ports
  #https_ingress_cidr_blocks     = var.lb_https_ingress_cidr_blocks
  #https_ingress_prefix_list_ids = var.lb_https_ingress_prefix_list_ids

  # Target Groups
#   deregistration_delay                          = var.lb_deregistration_delay
#   slow_start                                    = var.lb_slow_start
#   load_balancing_algorithm_type                 = var.lb_load_balancing_algorithm_type
#   stickiness                                    = var.lb_stickiness
#   target_group_health_check_enabled             = var.lb_target_group_health_check_enabled
#   target_group_health_check_interval            = var.lb_target_group_health_check_interval
#   target_group_health_check_path                = var.lb_target_group_health_check_path
#   target_group_health_check_timeout             = var.lb_target_group_health_check_timeout
#   target_group_health_check_healthy_threshold   = var.lb_target_group_health_check_healthy_threshold
#   target_group_health_check_unhealthy_threshold = var.lb_target_group_health_check_unhealthy_threshold
#   target_group_health_check_matcher             = var.lb_target_group_health_check_matcher

  # Certificates
  default_certificate_arn                         = aws_acm_certificate.this.arn
  #ssl_policy                                      = var.ssl_policy
  #additional_certificates_arn_for_https_listeners = var.additional_certificates_arn_for_https_listeners
}

#------------------------------------------------------------------------------
# AWS ECS SERVICE
#------------------------------------------------------------------------------
# resource "aws_ecs_service" "service" {
#   name = "${var.name_prefix}-service"
#   # capacity_provider_strategy - (Optional) The capacity provider strategy to use for the service. Can be one or more. Defined below.
#   cluster                            = var.ecs_cluster_arn
#   deployment_maximum_percent         = var.deployment_maximum_percent
#   deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
#   desired_count                      = var.desired_count
#   enable_ecs_managed_tags            = var.enable_ecs_managed_tags
#   health_check_grace_period_seconds  = var.health_check_grace_period_seconds
#   launch_type                        = "FARGATE"
#   force_new_deployment               = var.force_new_deployment

#   dynamic "load_balancer" {
#     for_each = module.ecs-alb.lb_http_tgs_map_arn_port
#     content {
#       target_group_arn = load_balancer.key
#       container_name   = var.container_name
#       container_port   = load_balancer.value
#     }
#   }
#   dynamic "load_balancer" {
#     for_each = module.ecs-alb.lb_https_tgs_map_arn_port
#     content {
#       target_group_arn = load_balancer.key
#       container_name   = var.container_name
#       container_port   = load_balancer.value
#     }
#   }
#   network_configuration {
#     security_groups  = concat([aws_security_group.ecs_tasks_sg.id], var.security_groups)
#     subnets          = var.assign_public_ip ? var.public_subnets : var.private_subnets
#     assign_public_ip = var.assign_public_ip
#   }
#   dynamic "ordered_placement_strategy" {
#     for_each = var.ordered_placement_strategy
#     content {
#       type  = ordered_placement_strategy.value.type
#       field = lookup(ordered_placement_strategy.value, "field", null)
#     }
#   }
#   dynamic "placement_constraints" {
#     for_each = var.placement_constraints
#     content {
#       expression = lookup(placement_constraints.value, "expression", null)
#       type       = placement_constraints.value.type
#     }
#   }
#   platform_version = var.platform_version
#   propagate_tags   = var.propagate_tags
#   dynamic "service_registries" {
#     for_each = var.service_registries
#     content {
#       registry_arn   = service_registries.value.registry_arn
#       port           = lookup(service_registries.value, "port", null)
#       container_name = lookup(service_registries.value, "container_name", null)
#       container_port = lookup(service_registries.value, "container_port", null)
#     }
#   }
#   task_definition = var.task_definition_arn
#   tags = {
#     Name = "${var.name_prefix}-ecs-tasks-sg"
#   }
# }

# #------------------------------------------------------------------------------
# # AWS SECURITY GROUP - ECS Tasks, allow traffic only from Load Balancer
# #------------------------------------------------------------------------------
# resource "aws_security_group" "ecs_tasks_sg" {
#   name        = "${var.name_prefix}-ecs-tasks-sg"
#   description = "Allow inbound access from the LB only"
#   vpc_id      = var.vpc_id

#   tags = {
#     Name = "${var.name_prefix}-ecs-tasks-sg"
#   }
# }

# resource "aws_security_group_rule" "egress" {
#   security_group_id = aws_security_group.ecs_tasks_sg.id
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "ingress_through_http" {
#   for_each                 = toset(module.ecs-alb.lb_http_tgs_ports)
#   security_group_id        = aws_security_group.ecs_tasks_sg.id
#   type                     = "ingress"
#   from_port                = each.key
#   to_port                  = each.key
#   protocol                 = "tcp"
#   source_security_group_id = module.ecs-alb.aws_security_group_lb_access_sg_id
# }

# resource "aws_security_group_rule" "ingress_through_https" {
#   for_each                 = toset(module.ecs-alb.lb_https_tgs_ports)
#   security_group_id        = aws_security_group.ecs_tasks_sg.id
#   type                     = "ingress"
#   from_port                = each.key
#   to_port                  = each.key
#   protocol                 = "tcp"
#   source_security_group_id = module.ecs-alb.aws_security_group_lb_access_sg_id
# }

# module "ecs-autoscaling" {
#   count = var.enable_autoscaling ? 1 : 0

#   source  = "cn-terraform/ecs-service-autoscaling/aws"
#   version = "1.0.1"

#   name_prefix               = var.name_prefix
#   ecs_cluster_name          = var.ecs_cluster_name
#   ecs_service_name          = aws_ecs_service.service.name
#   max_cpu_threshold         = var.max_cpu_threshold
#   min_cpu_threshold         = var.min_cpu_threshold
#   max_cpu_evaluation_period = var.max_cpu_evaluation_period
#   min_cpu_evaluation_period = var.min_cpu_evaluation_period
#   max_cpu_period            = var.max_cpu_period
#   min_cpu_period            = var.min_cpu_period
#   scale_target_max_capacity = var.scale_target_max_capacity
#   scale_target_min_capacity = var.scale_target_min_capacity
# }