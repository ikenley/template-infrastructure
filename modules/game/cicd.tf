#------------------------------------------------------------------------------
# CI/CD
#------------------------------------------------------------------------------

locals {
  codebuild_project_name = "${local.id}-codebuild-main"
}

# resource "aws_ecr_repository" "api" {
#   name                 = "${local.id}-api"
#   image_tag_mutability = "IMMUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }

# resource "aws_ecr_repository_policy" "api" {
#   repository = aws_ecr_repository.api.name
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Sid" : "LambdaECRImageRetrievalPolicy",
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service" : "lambda.amazonaws.com"
#         },
#         "Action" : [
#           "ecr:BatchGetImage",
#           "ecr:GetDownloadUrlForLayer"
#         ]
#       }
#     ]
#   })
# }

# resource "aws_ecr_lifecycle_policy" "api" {
#   repository = aws_ecr_repository.api.name

#   policy = <<EOF
# {
#   "rules": [
#     {
#       "rulePriority": 1,
#       "description": "Keep last 3 images",
#       "selection": {
#         "tagStatus": "any",
#         "countType": "imageCountMoreThan",
#         "countNumber": 3
#       },
#       "action": {
#         "type": "expire"
#       }
#     }
#   ]
# }
# EOF
# }

# resource "aws_ecr_repository" "lambda" {
#   name                 = "${local.id}-lambda"
#   image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }

# resource "aws_ecr_repository_policy" "lambda" {
#   repository = aws_ecr_repository.lambda.name
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Sid" : "LambdaECRImageRetrievalPolicy",
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service" : "lambda.amazonaws.com"
#         },
#         "Action" : [
#           "ecr:BatchGetImage",
#           "ecr:GetDownloadUrlForLayer"
#         ]
#       }
#     ]
#   })
# }

# resource "aws_ecr_lifecycle_policy" "lambda" {
#   repository = aws_ecr_repository.lambda.name

#   policy = <<EOF
# {
#   "rules": [
#     {
#       "rulePriority": 1,
#       "description": "Keep last 3 images",
#       "selection": {
#         "tagStatus": "any",
#         "countType": "imageCountMoreThan",
#         "countNumber": 3
#       },
#       "action": {
#         "type": "expire"
#       }
#     }
#   ]
# }
# EOF
# }

#------------------------------------------------------------------------------
# CodeBuild
#------------------------------------------------------------------------------

resource "aws_codebuild_project" "codebuild_main" {
  name        = local.codebuild_project_name
  description = "CodeBuild project for ${local.id}"

  service_role = aws_iam_role.codebuild_main.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type            = "GITHUB"
    location        = local.git_repo
    git_clone_depth = 1
    buildspec       = "buildspec.yml"
  }

  source_version = var.git_branch

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  vpc_config {
    vpc_id = data.aws_ssm_parameter.vpc_id.value

    subnets = local.private_subnets

    security_group_ids = [aws_security_group.codebuild_main.id]
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
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

    # environment_variable {
    #   name  = "API_REPOSITORY_URL"
    #   value = aws_ecr_repository.api.repository_url
    # }
    # environment_variable {
    #   name  = "API_REPOSITORY_NAME"
    #   value = aws_ecr_repository.api.name
    # }

    # environment_variable {
    #   name  = "LAMBDA_REPOSITORY_URL"
    #   value = aws_ecr_repository.lambda.repository_url
    # }
    # environment_variable {
    #   name  = "LAMBDA_REPOSITORY_NAME"
    #   value = aws_ecr_repository.lambda.name
    # }

    # environment_variable {
    #   name  = "API_FUNCTION_NAME"
    #   value = module.api_lambda.lambda_function_name
    # }
    # environment_variable {
    #   name  = "JOB_RUNNER_FUNCTION_NAME"
    #   value = aws_lambda_function.job_runner.function_name
    # }

    environment_variable {
      name  = "SITE_S3_BUCKET_NAME"
      value = module.frontend.bucket_id
    }

    environment_variable {
      name  = "SITE_S3_KEY_PREFIX"
      value = "game"
    }

    environment_variable {
      name  = "CDN_DISTRIBUTION_ID"
      value = module.frontend.cdn_distribution_id
    }

    environment_variable {
      name  = "ACTIVE_VERSION_SSM_PARAMETER_NAME"
      value = module.frontend.active_version_ssm_parameter_name
    }

    environment_variable {
      name  = "KVS_ARN"
      value = module.frontend.kvs_arn
    }

    environment_variable {
      name  = "VITE_API_URL_PREFIX"
      value = "https://${var.domain_name}/ai/api"
    }

    environment_variable {
      name  = "VITE_AUTH_API_URL_PREFIX"
      value = "https://${data.aws_ssm_parameter.auth_domain_name.value}/auth/api"
    }
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
      # {
      #   "Sid" : "AllowLambdaUpdate",
      #   "Effect" : "Allow",
      #   "Action" : [
      #     "lambda:UpdateFunctionCode"
      #   ],
      #   "Resource" : [
      #     module.api_lambda.lambda_function_arn,
      #     aws_lambda_function.job_runner.arn
      #   ]
      # },
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
        "Sid" : "AllowActiveVersionSsmParameter",
        "Effect" : "Allow",
        "Action" : [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        "Resource" : [
          module.frontend.active_version_ssm_parameter_arn
        ]
      },
      {
        "Sid" : "AllowCdnKeyValueStore",
        "Effect" : "Allow",
        "Action" : [
          "cloudfront-keyvaluestore:DescribeKeyValueStore",
          "cloudfront-keyvaluestore:GetKey",
          "cloudfront-keyvaluestore:PutKey",
          "cloudfront-keyvaluestore:DeleteKey",
          "cloudfront-keyvaluestore:ListKeys",
          "cloudfront-keyvaluestore:UpdateKeys"
        ],
        "Resource" : [
          module.frontend.kvs_arn
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

