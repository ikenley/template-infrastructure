# ------------------------------------------------------------------------------
# Prediction application
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  id            = "${var.namespace}-${var.env}-prediction"
  output_prefix = "/${var.namespace}/${var.env}/prediction"

  app_domain    = "${var.dns_subdomain}.${var.domain_name}"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    is_prod     = var.is_prod
  })
}

# module "application" {
#   source = "../application"

#   name          = var.name
#   env           = var.env
#   is_prod       = var.is_prod
#   domain_name   = var.domain_name
#   dns_subdomain = var.dns_subdomain

#   vpc_id           = var.vpc_id
#   vpc_cidr         = var.vpc_cidr
#   azs              = var.azs
#   public_subnets   = var.public_subnets
#   private_subnets  = var.private_subnets
#   database_subnets = var.database_subnets

#   host_in_public_subnets = var.host_in_public_subnets

#   alb_arn   = var.alb_arn
#   alb_sg_id = var.alb_sg_id

#   ecs_cluster_arn  = var.ecs_cluster_arn
#   ecs_cluster_name = var.ecs_cluster_name

#   container_names  = var.container_names
#   container_ports  = var.container_ports
#   container_cpu    = var.container_cpu
#   container_memory = var.container_memory
#   container_secrets = [
#     {
#       name      = "ConnectionStrings__main"
#       valueFrom = "${aws_ssm_parameter.prediction_app_user__connection_string.arn}"
#     }
#   ]

#   code_pipeline_s3_bucket_name = var.code_pipeline_s3_bucket_name
#   source_full_repository_id    = var.source_full_repository_id
#   source_branch_name           = var.source_branch_name
#   codestar_connection_arn      = var.codestar_connection_arn
#   create_e2e_tests             = var.create_e2e_tests
#   e2e_codebuild_buildspec_path = var.e2e_codebuild_buildspec_path
#   e2e_codebuild_env_vars       = var.e2e_codebuild_env_vars

#   auth_jwt_authority         = var.auth_jwt_authority
#   auth_cognito_users_pool_id = var.auth_cognito_users_pool_id
#   auth_client_id             = var.auth_client_id
#   auth_aud                   = var.auth_aud

#   rds_output_prefix = var.rds_output_prefix
#   app_output_prefix = local.output_prefix

#   tags = var.tags
# }

# resource "aws_iam_policy" "ecs_task_execution_role" {
#   name        = "${local.id}-ecs-task-execution-role"
#   description = "Additional permissions for ${local.id} ECS task execution role"

#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Sid" : "AllowSSMDescribeParameters",
#         "Effect" : "Allow",
#         "Action" : [
#           "ssm:DescribeParameters"
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Sid" : "AllowSSMGetParameters",
#         "Effect" : "Allow",
#         "Action" : [
#           "ssm:GetParameter",
#           "ssm:GetParameters",
#           "ssm:GetParametersByPath"
#         ],
#         "Resource" : [
#           aws_ssm_parameter.prediction_app_user__connection_string.arn
#         ]
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
#   role       = module.application.task_execution_role_name
#   policy_arn = aws_iam_policy.ecs_task_execution_role.arn
# }

# ------------------------------------------------------------------------------
# Dynamo tables
# ------------------------------------------------------------------------------

module "dynamo_users" {
  source = "../../modules/dynamo_table"

  namespace = var.namespace
  env       = var.env
  is_prod   = var.is_prod

  name     = "Users"
  hash_key = "Id"

  attributes = [{ "name" : "Id", "type" : "S" }]

  role_names = [
    module.api_lambda.lambda_role_name,
    //module.lambda_revisit_prediction_function.lambda_role_name
  ]
}

module "dynamo_predictions" {
  source = "../../modules/dynamo_table"

  namespace = var.namespace
  env       = var.env
  is_prod   = var.is_prod

  name      = "Predictions"
  hash_key  = "UserId"
  range_key = "Id"

  role_names = [
    module.api_lambda.lambda_role_name,
    //module.lambda_revisit_prediction_function.lambda_role_name
  ]

  attributes = [
    { "name" : "Id", "type" : "S" },
    { "name" : "UserId", "type" : "S" },
    { "name" : "RevisitOn", "type" : "S" }
  ]

  global_secondary_index = [{
    name               = "RevisitOn"
    write_capacity     = 1
    read_capacity      = 1
    hash_key           = "RevisitOn"
    range_key          = "UserId"
    projection_type    = "INCLUDE"
    non_key_attributes = ["Id", "Name"]
  }]
}

# ------------------------------------------------------------------------------
# Revisit Prediction Lambda Function
# ------------------------------------------------------------------------------

# module "lambda_revisit_prediction_function" {
#   source = "terraform-aws-modules/lambda/aws"

#   function_name = "${var.namespace}-revisit-prediction"
#   description   = "Check for Predictions that have a RevisitOn date"
#   handler       = "index.handler"
#   runtime       = "nodejs14.x"
#   publish       = true

#   source_path = "${path.module}/revisit_prediction_function"

#   environment_variables = {
#     Serverless             = "Terraform"
#     USERS_TABLE_NAME       = module.dynamo_users.table_name
#     PREDICTIONS_TABLE_NAME = module.dynamo_predictions.table_name
#     SES_EMAIL_ADDRESS      = var.ses_email_address
#   }

#   tags = var.tags
# }

# resource "aws_iam_policy" "revisit_prediction_function" {
#   name = "${var.name}-revisit-prediction-function-policy"

#   policy = templatefile("${path.module}/revisit_prediction_function_policy.json", {
#     ses_email_arn = var.ses_email_arn
#   })
# }

# resource "aws_iam_role_policy_attachment" "revisit_prediction_function_attach" {
#   role       = module.lambda_revisit_prediction_function.lambda_role_name
#   policy_arn = aws_iam_policy.revisit_prediction_function.arn
# }

# module "eventbridge_revisit_prediction_function" {
#   source  = "terraform-aws-modules/eventbridge/aws"
#   version = "1.4.0"

#   #bus_name = "${var.namespace}-bus"
#   create_bus = false

#   rules = {
#     predictions = {
#       name                = "daily-revisit-predictions"
#       description         = "Check predictions once daily"
#       schedule_expression = "cron(0 10 ? * * *)"
#       enabled             = true
#     }
#   }

#   # targets = {
#   #   predictions = [
#   #     {
#   #       name = "trigger-revisit-prediction-function"
#   #       arn  = module.lambda_revisit_prediction_function.lambda_function_arn
#   #     }
#   #   ]
#   # }

#   tags = var.tags
# }

# resource "aws_lambda_permission" "allow_eventbridge_revisit_prediction_function" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = module.lambda_revisit_prediction_function.lambda_function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = module.eventbridge_revisit_prediction_function.eventbridge_rule_arns["predictions"]
# }
