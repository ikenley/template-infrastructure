#------------------------------------------------------------------------------
# CodeBuild Flyway migrations
#------------------------------------------------------------------------------

locals {
  migration_id = "${local.codebuild_project_name}-migrations"
}

resource "aws_codebuild_project" "migrations" {
  name        = local.migration_id
  description = "Flyway migrations for ${var.name}"

  service_role = aws_iam_role.migrations.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  vpc_config {
    vpc_id = var.vpc_id
    subnets = var.private_subnets
    security_group_ids = [aws_security_group.migrations.id]
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ENV"
      value = var.env
    }

    environment_variable {
      name  = "DOCKER_USERNAME"
      value = "/docker/username"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "DOCKER_PASSWORD"
      value = "/docker/password"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "FLYWAY_URL"
      value = "${local.output_prefix}/flyway_url"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "FLYWAY_USER"
      value = "${local.output_prefix}/flyway_admin/pguser"
      type  = "PARAMETER_STORE"
    }
    environment_variable {
      name  = "FLYWAY_PASSWORD"
      value = "${local.output_prefix}/flyway_admin/pgpassword"
      type  = "PARAMETER_STORE"
    }
    environment_variable {
      name  = "FLYWAY_DEFAULT_SCHEMA"
      value = "flyway"
    }
    environment_variable {
      name  = "FLYWAY_CONNECT_RETRIES"
      value = "2"
    }
    environment_variable {
      name  = "FLYWAY_LOCATIONS"
      value = "filesystem:./sql"
    }
    environment_variable {
      name  = "FLYWAY_PLACEHOLDERS_PREDICTION_APP_USER_PW"
      value = "${local.output_prefix}/prediction_app_user/pgpassword"
      type  = "PARAMETER_STORE"
    }
    environment_variable {
      name  = "FLYWAY_PLACEHOLDERS_REVISIT_PREDICTION_USER_PW"
      value = "${local.output_prefix}/revisit_prediction/pgpassword"
      type  = "PARAMETER_STORE"
    }
    environment_variable {
      name  = "FLYWAY_PLACEHOLDERS_AUTH_SERVICE_USER_PW"
      value = "${local.output_prefix}/auth_service/pgpassword"
      type  = "PARAMETER_STORE"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/ikenley/prediction-app"
    git_clone_depth = 1
    buildspec       = "buildspec-migrations.yml"
  }

  source_version = var.source_branch_name

  tags = local.tags
}

resource "aws_security_group" "migrations" {
  name        = local.migration_id
  description = "${local.migration_id} sg"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = local.migration_id
  }
}

resource "aws_iam_role" "migrations" {
  name = local.migration_id

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

resource "aws_iam_policy" "migrations" {
  name = local.migration_id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowVpc",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterfacePermission",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeDhcpOptions",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeVpcs",
                "iam:PassRole",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
            ],
            "Resource": ["*"]
        },
        {
            "Sid": "AllowS3",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketAcl",
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetBucketLocation",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::${var.code_pipeline_s3_bucket_name}",
                "arn:aws:s3:::${var.code_pipeline_s3_bucket_name}/*"
            ]
        },
        {
            "Sid": "AllowCodebuildReportGroup",
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutCodeCoverages",
                "codebuild:BatchPutTestCases"
            ],
            "Resource": [
                "arn:aws:codebuild:us-east-1:${local.account_id}:report-group/${local.migration_id}-*"
            ]
        },
        {
            "Sid": "AllowLogs",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:PutLogEvents",
                "logs:CreateLogStream"
            ],
            "Resource": [
                "arn:aws:logs:us-east-1:${local.account_id}:log-group:/aws/codebuild/${local.migration_id}",
                "arn:aws:logs:us-east-1:${local.account_id}:log-group:/aws/codebuild/${local.migration_id}:*"
            ]
        },
        {
            "Sid": "AllowSSMDescribeParameters",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowSSMGetParameters",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": [
                "arn:aws:ssm:*:*:parameter/docker/*",
                "arn:aws:ssm:*:*:parameter/${var.name}/codebuild/*",
                "arn:aws:ssm:*:*:parameter${var.rds_output_prefix}/*",
                "arn:aws:ssm:*:*:parameter${local.output_prefix}/*"
            ]
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "migrations" {
  role       = aws_iam_role.migrations.name
  policy_arn = aws_iam_policy.migrations.arn
}
