#------------------------------------------------------------------------------
# CI/CD
#------------------------------------------------------------------------------

locals {
  codebuild_project_name = "${local.id}-codebuild-main"
}

resource "aws_ecr_repository" "api" {
  name                 = "${local.id}-api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "api" {
  repository = aws_ecr_repository.api.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "LambdaECRImageRetrievalPolicy",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })
}

resource "aws_ecr_repository" "lambda" {
  name                 = "${local.id}-lambda"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "lambda" {
  repository = aws_ecr_repository.lambda.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "LambdaECRImageRetrievalPolicy",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })
}

resource "aws_codepipeline" "this" {
  name     = local.id
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = data.aws_ssm_parameter.code_pipeline_s3_bucket_name.value
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
        "BranchName" : "prediction-api-gateway" # TODO change to var.git_branch
        "ConnectionArn" : data.aws_ssm_parameter.codestar_connection_arn.value
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
}

resource "aws_iam_role" "codepipeline" {
  name = "${local.id}-codepipeline"

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

resource "aws_iam_role_policy" "codepipeline" {
  name = aws_iam_role.codepipeline.name
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : [
          "iam:PassRole"
        ],
        "Resource" : "*",
        "Effect" : "Allow",
        "Condition" : {
          "StringEqualsIfExists" : {
            "iam:PassedToService" : [
              "cloudformation.amazonaws.com",
              "elasticbeanstalk.amazonaws.com",
              "ec2.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      },
      {
        "Action" : [
          "codecommit:CancelUploadArchive",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "codestar-connections:UseConnection"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "cloudwatch:*",
          "sns:*",
          "cloudformation:*",
          "sqs:*",
          "ecs:*"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "lambda:InvokeFunction",
          "lambda:ListFunctions"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "opsworks:CreateDeployment",
          "opsworks:DescribeApps",
          "opsworks:DescribeCommands",
          "opsworks:DescribeDeployments",
          "opsworks:DescribeInstances",
          "opsworks:DescribeStacks",
          "opsworks:UpdateApp",
          "opsworks:UpdateStack"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:SetStackPolicy",
          "cloudformation:ValidateTemplate"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "devicefarm:ListProjects",
          "devicefarm:ListDevicePools",
          "devicefarm:GetRun",
          "devicefarm:GetUpload",
          "devicefarm:CreateUpload",
          "devicefarm:ScheduleRun"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "servicecatalog:ListProvisioningArtifacts",
          "servicecatalog:CreateProvisioningArtifact",
          "servicecatalog:DescribeProvisioningArtifact",
          "servicecatalog:DeleteProvisioningArtifact",
          "servicecatalog:UpdateProduct"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudformation:ValidateTemplate"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:DescribeImages"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "states:DescribeExecution",
          "states:DescribeStateMachine",
          "states:StartExecution"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "appconfig:StartDeployment",
          "appconfig:StopDeployment",
          "appconfig:GetDeployment"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          "arn:aws:s3:::${data.aws_ssm_parameter.code_pipeline_s3_bucket_name.value}",
          "arn:aws:s3:::${data.aws_ssm_parameter.code_pipeline_s3_bucket_name.value}/*"
        ]
      }
    ],
    "Version" : "2012-10-17"
  })
}

#------------------------------------------------------------------------------
# CodeBuild
#------------------------------------------------------------------------------

resource "aws_codebuild_project" "codebuild_main" {
  name        = local.codebuild_project_name
  description = "CodeBuild project for ${local.id}"

  service_role = aws_iam_role.codebuild_main.arn

  artifacts {
    type = "CODEPIPELINE"
    name = aws_codepipeline.this.name
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  vpc_config {
    vpc_id = data.aws_ssm_parameter.vpc_id.value

    subnets = var.private_subnets

    security_group_ids = [aws_security_group.codebuild_main.id]
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
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
      name  = "API_REPOSITORY_URL"
      value = aws_ecr_repository.api.repository_url
    }
    environment_variable {
      name  = "API_REPOSITORY_NAME"
      value = aws_ecr_repository.api.name
    }

    environment_variable {
      name  = "LAMBDA_REPOSITORY_URL"
      value = aws_ecr_repository.lambda.repository_url
    }
    environment_variable {
      name  = "LAMBDA_REPOSITORY_NAME"
      value = aws_ecr_repository.lambda.name
    }

    environment_variable {
      name  = "API_FUNCTION_NAME"
      value = module.api_lambda.lambda_function_name
    }

    environment_variable {
      name  = "SITE_S3_BUCKET_NAME"
      value = module.frontend.bucket_id
    }

    # environment_variable {
    #   name  = "SITE_S3_KEY_PREFIX"
    #   value = "prediction"
    # }

    environment_variable {
      name  = "CDN_DISTRIBUTION_ID"
      value = module.frontend.cdn_distribution_id
    }

    environment_variable {
      name = "REACT_APP_API_URL_PREFIX"
      value = "https://api.${local.app_domain}/api"
    }

    environment_variable {
      name = "REACT_APP_AUTH_API_URL_PREFIX"
      value = "https://${data.aws_ssm_parameter.auth_domain_name.value}/auth/api"
    }
  }

  source {
    type = "CODEPIPELINE"
  }

  tags = local.tags
}

resource "aws_security_group" "codebuild_main" {
  name        = local.codebuild_project_name
  description = "${local.codebuild_project_name} sg"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = local.codebuild_project_name
  }
}

resource "aws_iam_role" "codebuild_main" {
  name = "${local.id}-codebuild-main"

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

resource "aws_iam_role_policy_attachment" "codebuild_main" {
  role       = aws_iam_role.codebuild_main.name
  policy_arn = aws_iam_policy.codebuild_main.arn
}

resource "aws_iam_policy" "codebuild_main" {
  name = local.codebuild_project_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowVpc",
        "Effect" : "Allow",
        "Action" : [
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
        "Resource" : ["*"]
      },
      {
        "Sid" : "AllowS3",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucketAcl",
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:GetObjectVersion"
        ],
        "Resource" : [
          "arn:aws:s3:::${data.aws_ssm_parameter.code_pipeline_s3_bucket_name.value}",
          "arn:aws:s3:::${data.aws_ssm_parameter.code_pipeline_s3_bucket_name.value}/*"
        ]
      },
      {
        "Sid" : "AllowCodebuildReportGroup",
        "Effect" : "Allow",
        "Action" : [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutCodeCoverages",
          "codebuild:BatchPutTestCases"
        ],
        "Resource" : [
          "arn:aws:codebuild:us-east-1:${local.account_id}:report-group/${local.codebuild_project_name}-*"
        ]
      },
      {
        "Sid" : "AllowLogs",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ],
        "Resource" : [
          "arn:aws:logs:us-east-1:${local.account_id}:log-group:/aws/codebuild/${local.codebuild_project_name}",
          "arn:aws:logs:us-east-1:${local.account_id}:log-group:/aws/codebuild/${local.codebuild_project_name}:*"
        ]
      },
      {
        "Sid" : "AllowECR",
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:DescribeRepositories",
          "ecr:CreateRepository",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:SetRepositoryPolicy",
          "ecr:GetRepositoryPolicy",
          "ecs:UpdateService"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowLambdaUpdate",
        "Effect" : "Allow",
        "Action" : [
          "lambda:UpdateFunctionCode"
        ],
        "Resource" : [
          module.api_lambda.lambda_function_arn
        ]
      },
      {
        "Sid" : "AllowSSMDescribeParameters",
        "Effect" : "Allow",
        "Action" : [
          "ssm:DescribeParameters"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowSSMGetParameters",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameters"
        ],
        "Resource" : [
          "arn:aws:ssm:*:*:parameter/docker/*",
          "arn:aws:ssm:*:*:parameter/${local.id}/codebuild/*",
        ]
      },
      {
        "Sid" : "AllowS3Site",
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          "arn:aws:s3:::${module.frontend.bucket_id}",
          "arn:aws:s3:::${module.frontend.bucket_id}/*"
        ]
      },
      {
        "Sid" : "AllowCDN",
        "Effect" : "Allow",
        "Action" : [
          "cloudfront:*"
        ],
        "Resource" : [
          "arn:aws:cloudfront::${local.account_id}:distribution/${module.frontend.cdn_distribution_id}"
        ]
      }
    ]
  })
}

