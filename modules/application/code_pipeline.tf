#------------------------------------------------------------------------------
# CodePipeline
#------------------------------------------------------------------------------

locals {
  e2e_project_name = "${local.codebuild_project_name}-e2e-tests"
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

resource "aws_iam_policy" "codebuild_policy" {
  name = "${var.name}-codebuild-policy"

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
  name = "${local.e2e_project_name}-codebuild-role"

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
  name = "${var.name}-codebuild-policy"

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
