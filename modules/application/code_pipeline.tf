#------------------------------------------------------------------------------
# CodePipeline
#------------------------------------------------------------------------------

locals {
  e2e_project_name = "${local.codebuild_project_name}-e2e-tests"
  migration_id = "${local.codebuild_project_name}-migrations"
}

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

    action {
      name             = "Migrations"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      version          = "1"

      configuration = {
        ProjectName = local.migration_id
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
        "ClusterName" : local.ecs_cluster_name
        "ServiceName" : aws_ecs_service.this.name
      }
    }
  }

  stage {
    name = "EndToEndTests"

    action {
      name             = "EndToEndTests"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["E2ETestsArtifact"]
      version          = "1"

      configuration = {
        ProjectName = local.e2e_project_name
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
# CodeBuild
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
    image                       = "aws/codebuild/standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ENV"
      value = var.env
    }

    environment_variable {
      name  = "BRANCH_NAME"
      value = var.source_branch_name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }

    dynamic "environment_variable" {
      for_each = aws_ecr_repository.this.*
      content {
        name  = "${upper(replace(environment_variable.value.name, "${var.name}-", ""))}_IMAGE_REPO_NAME"
        value = environment_variable.value.name
      }
    }

  }

  source {
    type = "CODEPIPELINE"
  }

  tags = local.tags
}

resource "aws_iam_role" "codebuild_role" {
  name = "${var.name}-build-codebuild-role"

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

resource "aws_iam_policy" "codebuild_policy" {
  name = "${var.name}-build-codebuild-policy"

  policy = templatefile("${path.module}/codebuild_policy.tpl", {
    account_id                   = local.account_id
    code_pipeline_s3_bucket_name = var.code_pipeline_s3_bucket_name
    ecr_arns                     = jsonencode(aws_ecr_repository.this.*.arn)
    codebuild_project_name       = local.codebuild_project_name
    name                         = var.name
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

#------------------------------------------------------------------------------
# CodeBuild End-to-end (E2E) test
#------------------------------------------------------------------------------

resource "aws_codebuild_project" "e2e_test_codebuild" {
  name        = local.e2e_project_name
  description = "CodeBuild project for ${var.name} E2E tests"

  service_role = aws_iam_role.e2e_test_codebuild.arn

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
    image                       = "aws/codebuild/standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ENV"
      value = var.env
    }

    environment_variable {
      name  = "BRANCH_NAME"
      value = var.source_branch_name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }

    dynamic "environment_variable" {
      for_each = var.e2e_codebuild_env_vars
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }

  }

  source {
    type = "CODEPIPELINE"
  }

  tags = local.tags
}

resource "aws_iam_role" "e2e_test_codebuild" {
  name = "${local.e2e_project_name}-e2e-codebuild-role"

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

resource "aws_iam_policy" "e2e_test_codebuild" {
  name = "${var.name}-e2e-codebuild-policy"

  policy = templatefile("${path.module}/codebuild_policy.tpl", {
    account_id                   = local.account_id
    code_pipeline_s3_bucket_name = var.code_pipeline_s3_bucket_name
    ecr_arns                     = jsonencode(aws_ecr_repository.this.*.arn)
    codebuild_project_name       = local.e2e_project_name
    name                         = var.name
  })
}

resource "aws_iam_role_policy_attachment" "e2e_test_codebuild" {
  role       = aws_iam_role.e2e_test_codebuild.name
  policy_arn = aws_iam_policy.e2e_test_codebuild.arn
}

#------------------------------------------------------------------------------
# CodeBuild Flyway migrations
#------------------------------------------------------------------------------

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
      value = "${var.app_output_prefix}/flyway_url"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "FLYWAY_USER"
      value = "${var.app_output_prefix}/flyway_admin/pguser"
      type  = "PARAMETER_STORE"
    }
    environment_variable {
      name  = "FLYWAY_PASSWORD"
      value = "${var.app_output_prefix}/flyway_admin/pgpassword"
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
      value = "${var.app_output_prefix}/prediction_app_user/pgpassword"
      type  = "PARAMETER_STORE"
    }
    environment_variable {
      name  = "FLYWAY_PLACEHOLDERS_REVISIT_PREDICTION_USER_PW"
      value = "${var.app_output_prefix}/revisit_prediction/pgpassword"
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
            "Sid": "AllowSSMGetParametersDocker",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": [
                "arn:aws:ssm:*:*:parameter/docker/*",
                "arn:aws:ssm:*:*:parameter/${var.name}/codebuild/*",
                "arn:aws:ssm:*:*:parameter${var.rds_output_prefix}/*",
                "arn:aws:ssm:*:*:parameter${var.app_output_prefix}/*"
            ]
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "migrations" {
  role       = aws_iam_role.migrations.name
  policy_arn = aws_iam_policy.migrations.arn
}