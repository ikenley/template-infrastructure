#-------------------------------------------------------------------------------
# Example "spoke" VPC
# This simulates a normal workload account
#-------------------------------------------------------------------------------

resource "aws_vpc" "spoke_vpc_a" {
  cidr_block           = local.spoke_vpc_a_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "spoke-vpc-a"
  }
}

resource "aws_subnet" "spoke_vpc_a_protected_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.spoke_vpc_a.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.spoke_vpc_a_cidr, 8, 10 + count.index)

  tags = {
    Name = "spoke-vpc-a/${data.aws_availability_zones.available.names[count.index]}/protected-subnet"
  }
}

resource "aws_subnet" "spoke_vpc_a_endpoint_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.spoke_vpc_a.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.spoke_vpc_a_cidr, 8, 20 + count.index)

  tags = {
    Name = "spoke-vpc-a/${data.aws_availability_zones.available.names[count.index]}/endpoint-subnet"
  }
}

resource "aws_subnet" "spoke_vpc_a_tgw_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.spoke_vpc_a.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.spoke_vpc_a_cidr, 8, 30 + count.index)

  tags = {
    Name = "spoke-vpc-a/${data.aws_availability_zones.available.names[count.index]}/tgw-subnet"
  }
}


resource "aws_route_table" "spoke_vpc_a_route_table" {
  vpc_id = aws_vpc.spoke_vpc_a.id
  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  tags = {
    Name = "spoke-vpc-a/route-table"
  }
}

resource "aws_route_table_association" "spoke_vpc_a_route_table_association" {
  count          = length(aws_subnet.spoke_vpc_a_protected_subnet[*])
  subnet_id      = aws_subnet.spoke_vpc_a_protected_subnet[count.index].id
  route_table_id = aws_route_table.spoke_vpc_a_route_table.id
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

