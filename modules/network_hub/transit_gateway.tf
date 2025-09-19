#-------------------------------------------------------------------------------
# Configure transit gateway in central hub VPC and attach spoke VPCs
#-------------------------------------------------------------------------------

resource "aws_ec2_transit_gateway" "tgw" {
  tags = {
    Name = "${local.id}-transit-gateway"
  }
}

#-------------------------------------------------------------------------------
# Hub attachement
#-------------------------------------------------------------------------------

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  subnet_ids         = aws_subnet.hub_vpc_tgw_subnet[*].id
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.hub_vpc.id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  appliance_mode_support = "enable"

  tags = {
    Name = "${local.id}-hub-vpc-attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "${local.id}-hub-route-table"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# Route propagation for Account A attachment to its route table
resource "aws_ec2_transit_gateway_route_table_propagation" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# resource "aws_ec2_transit_gateway_route" "hub_to_spoke" {
#   for_each = var.spoke_vpcs

#   destination_cidr_block         = each.value.cidr
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.route
# }

