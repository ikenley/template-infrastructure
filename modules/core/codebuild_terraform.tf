#------------------------------------------------------------------------------
# CodeBuild project which executes Terraform project
# In order to understand recursion, first you must understand recursion
#------------------------------------------------------------------------------

locals {
  codebuild_terraform_id = "${local.id}-terraform"
}

#------------------------------------------------------------------------------
# CodeBuild Terraform
#------------------------------------------------------------------------------

resource "aws_codebuild_project" "codebuild_terraform" {
  name        = local.codebuild_terraform_id
  description = "Flyway codebuild_terraform for ${var.name}"

  service_role = aws_iam_role.codebuild_terraform.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  # vpc_config {
  #   vpc_id = module.vpc.vpc_id
  #   # This must run in a public subnet. This project creates the NAT gateway.
  #   subnets            = module.vpc.public_subnets
  #   security_group_ids = [aws_security_group.codebuild_terraform.id]
  # }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
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
      name  = "PROJECT_PATH"
      value = "dev/core"
    }

    environment_variable {
      name  = "TERRAFORM_ACTION"
      value = "plan"
    }

    environment_variable {
      name  = "TF_VAR_docker_password"
      value = "/docker/password"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "TF_VAR_spend_money"
      value = "false"
    }

    environment_variable {
      name  = "TF_VAR_google_client_id"
      value = "/${var.namespace}/${var.env}/core/cognito/google_client_id"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "TF_VAR_google_client_secret"
      value = "/${var.namespace}/${var.env}/core/cognito/google_client_secret"
      type  = "PARAMETER_STORE"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/ikenley/template-infrastructure"
    git_clone_depth = 1
    buildspec       = "modules/core/buildspec-terraform.yml"
  }

  source_version = var.source_branch_name

  tags = local.tags
}

resource "aws_security_group" "codebuild_terraform" {
  name        = local.codebuild_terraform_id
  description = "${local.codebuild_terraform_id} sg"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = local.codebuild_terraform_id
  }
}

resource "aws_iam_role" "codebuild_terraform" {
  name = local.codebuild_terraform_id

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

# These permissions are quite broad, and should only be used by the Terraform project itself.
resource "aws_iam_policy" "codebuild_terraform" {
  name = local.codebuild_terraform_id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      # {
      #   "Effect" : "Deny",
      #   "Action" : "*",
      #   "Resource" : "*",
      #   "Condition" : {
      #     "NotIpAddress" : {
      #       "aws:SourceIp" : [
      #         "${var.cidr}"
      #       ]
      #     }
      #   }
      # },
      # TODO add deny for very narrow set of nevers
      {
        "Sid" : "AllowTerraform",
        "Effect" : "Allow",
        "Action" : [
          "*"
        ],
        "Resource" : ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_terraform" {
  role       = aws_iam_role.codebuild_terraform.name
  policy_arn = aws_iam_policy.codebuild_terraform.arn
}
