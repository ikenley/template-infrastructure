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
# Create new Transit Gateway subnet
#-------------------------------------------------------------------------------

resource "aws_subnet" "spoke_tgw_subnet" {
  count = length(var.spoke_vpc.transit_gateway_subnets)

  map_public_ip_on_launch = false
  vpc_id                  = var.spoke_vpc.id
  availability_zone       = var.spoke_vpc.transit_gateway_subnets[count.index].availability_zone
  cidr_block              = var.spoke_vpc.transit_gateway_subnets[count.index].cidr
  tags = {
    Name = local.resource_name
  }
}

resource "aws_route_table" "spoke_tgw_subnet" {
  count = length(var.spoke_vpc.transit_gateway_subnets)

  vpc_id = var.spoke_vpc.id
  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
  }
  tags = {
    Name = local.resource_name
  }
}

resource "aws_route_table_association" "spoke_tgw_subnet" {
  count = length(var.spoke_vpc.transit_gateway_subnets)

  route_table_id = aws_route_table.spoke_tgw_subnet[count.index].id
  subnet_id      = aws_subnet.spoke_tgw_subnet[count.index].id
}

#-------------------------------------------------------------------------------
# Transit Gateway attachement
#-------------------------------------------------------------------------------

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke" {
  subnet_ids         = aws_subnet.spoke_tgw_subnet[*].id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = var.spoke_vpc.id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  appliance_mode_support = "enable"

  tags = {
    Name = "${local.id}-vpc-attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = var.transit_gateway_id
  tags = {
    Name = "${local.id}-route-table"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route" "spoke_to_hub" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.hub_transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

