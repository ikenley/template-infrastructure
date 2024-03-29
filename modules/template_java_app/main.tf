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

