#-------------------------------------------------------------------------------
# Configure transit gateway in central hub VPC and attach spoke VPCs
#-------------------------------------------------------------------------------

resource "aws_ec2_transit_gateway" "tgw" {
  tags = {
    Name = "${local.id}-transit-gateway"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub_vpc_tgw_attachment" {
  subnet_ids                                      = aws_subnet.hub_vpc_tgw_subnet[*].id
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = aws_vpc.hub_vpc.id
  transit_gateway_default_route_table_association = false
  appliance_mode_support                          = "enable"
  tags = {
    Name = "${local.id}-hub-vpc-attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table" "hub_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "${local.id}-hub-route-table"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "hub_vpc_tgw_attachment_rt_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub_vpc_tgw_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_route_table.id
}
