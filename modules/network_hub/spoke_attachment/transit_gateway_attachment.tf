#-------------------------------------------------------------------------------
# Configure transit gateway attachement in "spoke" account VPC
#-------------------------------------------------------------------------------

locals {
  resource_name = "${local.id}-spoke-vpc-tgw"
}

#-------------------------------------------------------------------------------
# Hub route
#-------------------------------------------------------------------------------

resource "aws_ec2_transit_gateway_route" "hub_to_spoke" {
  provider = aws.hub

  destination_cidr_block         = var.spoke_vpc.cidr
  transit_gateway_attachment_id  = var.hub_transit_gateway_attachment_id
  transit_gateway_route_table_id = var.hub_transit_gateway_route_table_id
}

#-------------------------------------------------------------------------------
# Transit Gateway attachement
#-------------------------------------------------------------------------------

# Share resource across accounts
resource "aws_ram_resource_share" "tgw_spoke" {
  provider = aws.hub

  name = local.resource_name

  tags = {
    Name = local.resource_name
  }
}

# Share the transit gateway...
resource "aws_ram_resource_association" "tgw_spoke" {
  provider = aws.hub

  resource_arn       = var.transit_gateway_arn
  resource_share_arn = aws_ram_resource_share.tgw_spoke.id
}

# ...with the spoke account.
resource "aws_ram_principal_association" "tgw_spoke" {
  provider = aws.hub

  principal          = data.aws_caller_identity.spoke.account_id
  resource_share_arn = aws_ram_resource_share.tgw_spoke.id
}

# Create the VPC attachment in the spoke account...
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke" {
  provider = aws.spoke

  subnet_ids         = var.spoke_vpc.transit_gateway_subnet_ids
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = var.spoke_vpc.id

  depends_on = [
    aws_ram_principal_association.tgw_spoke,
    aws_ram_resource_association.tgw_spoke,
  ]

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  appliance_mode_support = "enable"

  tags = {
    Name = "${local.id}-vpc-attachment"
  }
}

# ...and accept it in the hub account.
resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "spoke" {
  provider = aws.hub

  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.spoke.id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${local.id}-vpc-attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table" "spoke" {
  provider = aws.hub

  transit_gateway_id = var.transit_gateway_id
  tags = {
    Name = "${local.id}-route-table"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke" {
  provider = aws.hub

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route" "spoke_to_hub" {
  provider = aws.hub

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.hub_transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

