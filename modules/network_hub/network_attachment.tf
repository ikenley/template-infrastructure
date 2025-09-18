#-------------------------------------------------------------------------------
# Configure transit gateway attachement in "spoke" account VPC
#-------------------------------------------------------------------------------

module "network_attachment_spoke_abc" {
  source = "./network_attachment"

  providers = {
    aws     = aws.spoke_abc
    aws.hub = aws.hub

    aws.spoke = aws.spoke_abc
  }

  namespace = var.namespace
  env       = var.env
  project   = var.project
  is_prod   = var.is_prod

  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  hub_transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  hub_transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id


  spoke_key = "spoke_abc"

  spoke_vpc = var.spoke_vpcs["spoke_abc"]
}
