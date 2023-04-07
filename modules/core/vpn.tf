# ------------------------------------------------------------------------------
# Amazon Client VPN
# https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/what-is.html 
# https://github.com/cloudposse/terraform-aws-ec2-client-vpn#output_full_client_configuration
# ------------------------------------------------------------------------------

module "ec2_client_vpn" {
  source  = "cloudposse/ec2-client-vpn/aws"
  version = "0.14.0"

  enabled = var.enable_client_vpn

  namespace   = var.namespace
  environment = var.env
  name        = "core"

  vpc_id             = module.vpc.vpc_id
  client_cidr        = var.vpc_client_cidr
  dns_servers        = [var.dns_server_ip]
  organization_name  = var.organization_name
  retention_in_days  = 30
  associated_subnets = module.vpc.private_subnets
  authorization_rules = [
    {
      authorize_all_groups = true
      description          = "Internet access"
      target_network_cidr  = "0.0.0.0/0"
    }
    ,{
      authorize_all_groups = true
      description          = "VPC access"
      target_network_cidr  = var.cidr
    }
  ]

  ca_common_name            = "vpn.internal.${var.domain_name}"
  root_common_name          = "vpn-client.internal.${var.domain_name}"
  server_common_name        = "vpn-server.internal.${var.domain_name}"
  export_client_certificate = true

  create_security_group = true

  logging_enabled     = false
  logging_stream_name = "${local.id}-client_vpn"

  additional_routes = [
    {
      destination_cidr_block = "0.0.0.0/0"
      description            = "Internet Route"
      target_vpc_subnet_id   = element(module.vpc.private_subnets, 0)
    }
  ]
}
