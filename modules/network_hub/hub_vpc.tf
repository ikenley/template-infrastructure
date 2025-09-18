#-------------------------------------------------------------------------------
# Create VPC for the centralized hub/egress network
# Fork of: https://github.com/aws-samples/aws-network-firewall-terraform/blob/main/hub_vpc.tf
#-------------------------------------------------------------------------------

resource "aws_vpc" "hub_vpc" {
  cidr_block       = var.hub_vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "${local.id}-hub-vpc"
  }
}

resource "aws_subnet" "hub_vpc_public_subnet" {
  count                   = length(var.availability_zones)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.hub_vpc.id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.hub_vpc_cidr, 8, 10 + count.index)
  depends_on              = [aws_internet_gateway.hub_vpc_igw]
  tags = {
    Name = "${local.id}-hub-vpc-public-${var.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "hub_vpc_firewall_subnet" {
  count                   = length(var.availability_zones)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.hub_vpc.id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.hub_vpc_cidr, 8, 20 + count.index)
  tags = {
    Name = "${local.id}-hub-vpc-firewall-${var.availability_zones[count.index]}"
  }
}

resource "aws_internet_gateway" "hub_vpc_igw" {
  vpc_id = aws_vpc.hub_vpc.id
  tags = {
    Name = "${local.id}-hub-vpc-internet-gateway"
  }
}

resource "aws_eip" "hub_vpc_nat_gw_eip" {
  count = length(var.availability_zones)
}

resource "aws_nat_gateway" "hub_vpc_nat_gw" {
  count         = length(var.availability_zones)
  depends_on    = [aws_internet_gateway.hub_vpc_igw, aws_subnet.hub_vpc_public_subnet]
  allocation_id = aws_eip.hub_vpc_nat_gw_eip[count.index].id
  subnet_id     = aws_subnet.hub_vpc_public_subnet[count.index].id
  tags = {
    Name = "${local.id}-hub-vpc-nat-${var.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "hub_vpc_tgw_subnet" {
  count                   = length(var.availability_zones)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.hub_vpc.id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.hub_vpc_cidr, 8, 30 + count.index)
  tags = {
    Name = "${local.id}-hub-vpc-tgw-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table" "hub_vpc_tgw_subnet_route_table" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.hub_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    # https://github.com/hashicorp/terraform-provider-aws/issues/16759
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.hub_vpc_anfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.hub_vpc_firewall_subnet[count.index].id], 0)
  }
  tags = {
    Name = "${local.id}-hub-vpc-tgw-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table_association" "hub_vpc_tgw_subnet_route_table_association" {
  count          = length(var.availability_zones)
  route_table_id = aws_route_table.hub_vpc_tgw_subnet_route_table[count.index].id
  subnet_id      = aws_subnet.hub_vpc_tgw_subnet[count.index].id
}

resource "aws_route_table" "hub_vpc_firewall_subnet_route_table" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.hub_vpc.id
  route {
    cidr_block         = var.super_cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hub_vpc_nat_gw[count.index].id
  }
  tags = {
    Name = "${local.id}-hub-vpc-firewall-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table_association" "hub_vpc_firewall_subnet_route_table_association" {
  count          = length(var.availability_zones)
  route_table_id = aws_route_table.hub_vpc_firewall_subnet_route_table[count.index].id
  subnet_id      = aws_subnet.hub_vpc_firewall_subnet[count.index].id
}

resource "aws_route_table" "hub_vpc_public_subnet_route_table" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.hub_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub_vpc_igw.id
  }
  route {
    cidr_block = var.super_cidr_block
    # https://github.com/hashicorp/terraform-provider-aws/issues/16759
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.hub_vpc_anfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.hub_vpc_firewall_subnet[count.index].id], 0)
  }
  tags = {
    Name = "${local.id}-hub-vpc-public-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table_association" "hub_vpc_public_subnet_route_table_association" {
  count          = length(var.availability_zones)
  route_table_id = aws_route_table.hub_vpc_public_subnet_route_table[count.index].id
  subnet_id      = aws_subnet.hub_vpc_public_subnet[count.index].id
}
