# ------------------------------------------------------------------------------
# Prediction application
# ------------------------------------------------------------------------------

module "application" {
  source = "../application"

  name          = var.name
  env           = var.env
  is_prod       = var.is_prod
  domain_name   = var.domain_name
  dns_subdomain = var.dns_subdomain

  vpc_id           = var.vpc_id
  vpc_cidr         = var.vpc_cidr
  azs              = var.azs
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  host_in_public_subnets = var.host_in_public_subnets

  alb_arn   = var.alb_arn
  alb_sg_id = var.alb_sg_id

  ecs_cluster_arn  = var.ecs_cluster_arn
  ecs_cluster_name = var.ecs_cluster_name

  container_names  = var.container_names
  container_ports  = var.container_ports
  container_cpu    = var.container_cpu
  container_memory = var.container_memory

  code_pipeline_s3_bucket_name = var.code_pipeline_s3_bucket_name
  source_full_repository_id    = var.source_full_repository_id
  source_branch_name           = var.source_branch_name
  codestar_connection_arn      = var.codestar_connection_arn

  auth_jwt_authority         = var.auth_jwt_authority
  auth_cognito_users_pool_id = var.auth_cognito_users_pool_id
  auth_client_id             = var.auth_client_id
  auth_aud                   = var.auth_aud

  tags = var.tags
}

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
    module.application.task_role_name,
    module.lambda_revisit_prediction_function.lambda_role_name
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
    module.application.task_role_name,
    module.lambda_revisit_prediction_function.lambda_role_name
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

module "lambda_revisit_prediction_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.namespace}-revisit-prediction"
  description   = "Check for Predictions that have a RevisitOn date"
  handler       = "index.handler"
  runtime       = "nodejs12.x"
  publish       = true

  source_path = "${path.module}/revisit_prediction_function"

  environment_variables = {
    Serverless             = "Terraform"
    USERS_TABLE_NAME       = module.dynamo_users.table_name
    PREDICTIONS_TABLE_NAME = module.dynamo_predictions.table_name
    SES_EMAIL_ADDRESS      = var.ses_email_address
  }

  tags = var.tags
}

// TODO
// AccessDenied: User `arn:aws:sts::924586450630:assumed-role/prediction-app-revisit-prediction/prediction-app-revisit-prediction' 
// is not authorized to perform `ses:SendEmail' 
// on resource `arn:aws:ses:us-east-1:924586450630:identity/predictions.ikenley@gmail.com'

resource "aws_iam_policy" "revisit_prediction_function" {
  name = "${var.name}-revisit-prediction-function-policy"

  policy = templatefile("${path.module}/revisit_prediction_function_policy.json", {
    ses_email_arn = var.ses_email_arn
  })
}

resource "aws_iam_role_policy_attachment" "revisit_prediction_function_attach" {
  role       = module.lambda_revisit_prediction_function.lambda_role_name
  policy_arn = aws_iam_policy.revisit_prediction_function.arn
}

module "eventbridge_revisit_prediction_function" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "1.4.0"

  #bus_name = "${var.namespace}-bus"
  create_bus = false

  rules = {
    predictions = {
      name                = "daily-revisit-predictions"
      description         = "Check predictions once daily"
      schedule_expression = "cron(0 10 ? * * *)"
      enabled             = true
    }
  }

  targets = {
    predictions = [
      {
        name = "trigger-revisit-prediction-function"
        arn  = module.lambda_revisit_prediction_function.lambda_function_arn
      }
    ]
  }

  tags = var.tags
}

resource "aws_lambda_permission" "allow_eventbridge_revisit_prediction_function" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_revisit_prediction_function.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_revisit_prediction_function.eventbridge_rule_arns["predictions"]
}
