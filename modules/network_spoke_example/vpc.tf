#-------------------------------------------------------------------------------
# Example "spoke" VPC
# This simulates a normal workload account
#-------------------------------------------------------------------------------

resource "aws_vpc" "spoke_vpc_a" {
  cidr_block           = var.cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "spoke-vpc-a"
  }
}

resource "aws_subnet" "spoke_vpc_a_protected_subnet" {
  count                   = length(var.availability_zones)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.spoke_vpc_a.id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.cidr, 8, 10 + count.index)

  tags = {
    Name = "spoke-vpc-a/${var.availability_zones[count.index]}/protected-subnet"
  }
}

resource "aws_subnet" "spoke_vpc_a_endpoint_subnet" {
  count                   = length(var.availability_zones)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.spoke_vpc_a.id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.cidr, 8, 20 + count.index)

  tags = {
    Name = "spoke-vpc-a/${var.availability_zones[count.index]}/endpoint-subnet"
  }
}

resource "aws_route_table" "spoke_vpc_a_route_table" {
  count = var.transit_gateway_id == "" ? 0 : 1

  vpc_id = aws_vpc.spoke_vpc_a.id
  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
  }
  tags = {
    Name = "spoke-vpc-a/route-table"
  }
}

resource "aws_route_table_association" "spoke_vpc_a_route_table_association" {
  count          = var.transit_gateway_id == "" ? 0 : length(aws_subnet.spoke_vpc_a_protected_subnet[*])
  subnet_id      = aws_subnet.spoke_vpc_a_protected_subnet[count.index].id
  route_table_id = aws_route_table.spoke_vpc_a_route_table[0].id
}

#-------------------------------------------------------------------------------
# vpc-endpoints
# Enable private, direct connection for EC2 <> SSM
#-------------------------------------------------------------------------------

resource "aws_security_group" "spoke_vpc_a_endpoint_sg" {
  name        = "${local.id}-spoke-vpc-a-sg-ssm-ec2-endpoints"
  description = "Allow TLS inbound traffic for SSM/EC2 endpoints"
  vpc_id      = aws_vpc.spoke_vpc_a.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.spoke_vpc_a.cidr_block]
  }
  tags = {
    Name = "${local.id}-spoke-vpc-a-sg-ssm-ec2-endpoints"
  }
}

resource "aws_vpc_endpoint" "spoke_vpc_a_ssm_endpoint" {
  vpc_id            = aws_vpc.spoke_vpc_a.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.spoke_vpc_a_endpoint_subnet[*].id
  security_group_ids = [
    aws_security_group.spoke_vpc_a_endpoint_sg.id,
  ]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "spoke_vpc_a_ssm_messages_endpoint" {
  vpc_id            = aws_vpc.spoke_vpc_a.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.spoke_vpc_a_endpoint_subnet[*].id
  security_group_ids = [
    aws_security_group.spoke_vpc_a_endpoint_sg.id,
  ]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "spoke_vpc_a_ec2_messages_endpoint" {
  vpc_id            = aws_vpc.spoke_vpc_a.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.spoke_vpc_a_endpoint_subnet[*].id
  security_group_ids = [
    aws_security_group.spoke_vpc_a_endpoint_sg.id,
  ]
  private_dns_enabled = true
}
