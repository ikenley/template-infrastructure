#------------------------------------------------------------------------------
# Application
# Creates a **FULL** stack application-
# AWS Fargate service with 2 containers:
#   - "client": NGINX SPA create-react-app with a reverse proxy
#   - An API backend (in this case a .NET Core API)
#
# Resources created:
#   - DNS record + SSL cert
#   - Application Load Balancer
#   - ECR repositories
#   - ECS Task Definition
#   - ECS Fargate Cluster + Service
#   - CodePipeline/CodeBuild CI/CD pipeline
#   - IAM roles/policies for all the above
# Future iterations may require that these parts be abstracted (e.g. ALB)
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  tags = merge(var.tags, {
    Terraform = true
  })
  account_id = data.aws_caller_identity.current.account_id

  # Need to create this locally to avoid circular dep
  codebuild_project_name = var.name
}

#------------------------------------------------------------------------------
# DNS
#------------------------------------------------------------------------------

data "aws_route53_zone" "this" {
  name = "${var.domain_name}."
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

#------------------------------------------------------------------------------
# Task Definition
# https://github.com/cn-terraform/terraform-aws-ecs-fargate-task-definition
#------------------------------------------------------------------------------

resource "aws_ecr_repository" "client" {
  name                 = "${var.name}-client"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "api" {
  name                 = "${var.name}-api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

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

resource "aws_iam_policy" "ecs_task_role_app_policy" {
  name        = "${var.name}-ecs-task-policy"
  description = "Additional permissions for ECS task application"

  policy = templatefile("${path.module}/ecs_task_role_policy.tpl", {
    name = var.name
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_app_policy_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_role_app_policy.arn
}

resource "aws_ecs_task_definition" "this" {
  family = var.name

  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name  = aws_ecr_repository.client.name
      image = "${aws_ecr_repository.client.repository_url}:latest"
      #cpu       = 512
      memory    = 512
      #essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/${aws_ecr_repository.client.name}",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name  = aws_ecr_repository.api.name
      image = "${aws_ecr_repository.api.repository_url}:latest"
      #cpu       = 10
      memory    = 512
      #essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/${aws_ecr_repository.api.name}",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "client" {
  name = "/ecs/${aws_ecr_repository.client.name}"

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "api" {
  name = "/ecs/${aws_ecr_repository.api.name}"

  tags = local.tags
}

# ECS Service
# https://github.com/cn-terraform/terraform-aws-ecs-fargate-service

#------------------------------------------------------------------------------
# AWS LOAD BALANCER
#------------------------------------------------------------------------------
module "alb" {
  source = "../ecs_alb"

  name_prefix = var.name
  vpc_id      = var.vpc_id

  # S3 Bucket
  block_s3_bucket_public_access = true

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  # Certificates
  default_certificate_arn = aws_acm_certificate.this.arn
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = 30
}

#------------------------------------------------------------------------------
# AWS ECS SERVICE
#------------------------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = var.name

  tags = local.tags
}

resource "aws_ecs_service" "this" {
  name                    = var.name
  cluster                 = aws_ecs_cluster.this.arn
  desired_count           = var.desired_count
  enable_ecs_managed_tags = true
  launch_type             = "FARGATE"

  dynamic "load_balancer" {
    for_each = module.alb.lb_http_tgs_map_arn_port
    content {
      target_group_arn = load_balancer.key
      container_name   = aws_ecr_repository.client.name
      container_port   = load_balancer.value
    }
  }

  network_configuration {
    security_groups  = concat([aws_security_group.ecs_tasks_sg.id], var.security_groups)
    subnets          = var.public_subnets # var.private_subnets
    assign_public_ip = true               # TODO make false
  }
  task_definition = aws_ecs_task_definition.this.arn

  lifecycle {
    ignore_changes = [
      # Ignore task_definition b/c this will be managed by CodePipeline
      task_definition,
    ]
  }

  tags = local.tags
}

#------------------------------------------------------------------------------
# AWS SECURITY GROUP - ECS Tasks, allow traffic only from Load Balancer
#------------------------------------------------------------------------------
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.name}-ecs-tasks-sg"
  description = "Allow inbound access from the LB only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-ecs-tasks-sg"
  }
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.ecs_tasks_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_through_http" {
  for_each                 = toset(module.alb.lb_http_tgs_ports)
  security_group_id        = aws_security_group.ecs_tasks_sg.id
  type                     = "ingress"
  from_port                = each.key
  to_port                  = each.key
  protocol                 = "tcp"
  source_security_group_id = module.alb.aws_security_group_lb_access_sg_id
}

#------------------------------------------------------------------------------
# CodePipeline
#------------------------------------------------------------------------------

resource "aws_codepipeline" "this" {
  name     = var.name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.code_pipeline_s3_bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        "BranchName" : var.source_branch_name
        "ConnectionArn" : var.codestar_connection_arn
        "FullRepositoryId" : var.source_full_repository_id
        "OutputArtifactFormat" : "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"

      configuration = {
        ProjectName = local.codebuild_project_name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["BuildArtifact"]
      version         = "1"

      configuration = {
        "ClusterName" : aws_ecs_cluster.this.name
        "ServiceName" : aws_ecs_service.this.name
      }
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.name}-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = templatefile("${path.module}/codepipeline_policy.tpl", {
    code_pipeline_s3_bucket_name = var.code_pipeline_s3_bucket_name
  })
}

#------------------------------------------------------------------------------
# CodePipeline
#------------------------------------------------------------------------------

resource "aws_codebuild_project" "this" {
  name        = local.codebuild_project_name
  description = "CodeBuild project for ${var.name}"

  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
    name = aws_codepipeline.this.name
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ENV"
      value = var.env
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }

    environment_variable {
      name  = "CLIENT_IMAGE_REPO_NAME"
      value = aws_ecr_repository.client.name
    }

    environment_variable {
      name  = "API_IMAGE_REPO_NAME"
      value = aws_ecr_repository.api.name
    }

  }

  source {
    type = "CODEPIPELINE"
  }

  tags = local.tags
}

resource "aws_iam_role" "codebuild_role" {
  name = "${var.name}-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = templatefile("${path.module}/codebuild_policy.tpl", {
    code_pipeline_s3_bucket_name = var.code_pipeline_s3_bucket_name
    ecr_arns = jsonencode([
      aws_ecr_repository.client.arn,
      aws_ecr_repository.api.arn
    ])
    codebuild_project_name = local.codebuild_project_name
  })
}
