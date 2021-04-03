
# ------------------------------------------------------------------------------
# Client VPN Endpoint
# ------------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Terraform = true
  })
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = "Client VPN endpoint for ${var.name}"
  server_certificate_arn = var.server_certificate_arn
  client_cidr_block      = var.client_cidr_block

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.root_certificate_chain_arn
  }

  connection_log_options {
    enabled              = true
    cloudwatch_log_group = aws_cloudwatch_log_group.this.name
    #cloudwatch_log_stream = aws_cloudwatch_log_stream.ls.name
  }

  tags = merge(local.tags, {
    Name = var.name
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/vpc/${var.name}-vpn"

  tags = local.tags
}

resource "aws_ec2_client_vpn_network_association" "this" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.subnet_id
  security_groups        = [module.internal_sg.this_security_group_id]
}

module "internal_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "vpc-endpoint-${var.name}-sg"
  description = "Security group for internal traffic within VPC endpoint"
  vpc_id      = var.vpc_id

  ingress_rules       = ["all-all"]
  ingress_cidr_blocks = [var.vpc_cidr]

  egress_rules = ["all-all"]
}

resource "aws_ec2_client_vpn_authorization_rule" "default" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = var.vpc_cidr
  authorize_all_groups   = true
  description            = "Default authorization rule"
}

# resource "aws_ec2_client_vpn_route" "default" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
#   destination_cidr_block = var.vpc_cidr
#   target_vpc_subnet_id   = aws_ec2_client_vpn_network_association.this.subnet_id
# }

resource "aws_ec2_client_vpn_authorization_rule" "internet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
  description            = "Allow access to the internet"
}

resource "aws_ec2_client_vpn_route" "internet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  destination_cidr_block = "0.0.0.0/0"
  target_vpc_subnet_id   = aws_ec2_client_vpn_network_association.this.subnet_id
}
