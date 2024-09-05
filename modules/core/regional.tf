#------------------------------------------------------------------------------
# Resources that can be created in multiple regions.
# This is primarily to enable a failover region.
#------------------------------------------------------------------------------

module "failover_region" {
  source = "./regional"

  providers = {
    aws = aws.failover
  }

  tags      = var.tags
  namespace = var.namespace
  env       = var.env
  name      = var.name
  is_prod   = var.is_prod

  spend_money = var.spend_money

  cidr             = var.failover_cidr
  dns_server_ip    = var.failover_dns_server_ip
  azs              = var.failover_azs
  public_subnets   = var.failover_public_subnets
  private_subnets  = var.failover_private_subnets
  database_subnets = var.failover_database_subnets
  vpc_client_cidr  = var.failover_vpc_client_cidr

  enable_s3_endpoint  = var.enable_s3_endpoint
  enable_bastion_host = var.enable_bastion_host
  enable_client_vpn   = var.enable_client_vpn

  docker_username = var.docker_username
  docker_password = var.docker_password

  ses_email_address  = var.ses_email_address
  source_branch_name = var.source_branch_name
}
