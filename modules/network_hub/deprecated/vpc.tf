#-------------------------------------------------------------------------------
# Core VPC setup
# Fork of: https://github.com/terraform-aws-modules/terraform-aws-vpc
#-------------------------------------------------------------------------------

locals {
  inspection_id = "${local.id}-inspection"

  vpc_id = aws_vpc.inspection_vpc.id

  len_public_subnets          = length(var.public_subnets)
  len_firewall_subnets        = length(var.firewall_subnets)
  len_transit_gateway_subnets = length(var.transit_gateway_subnets)
}

resource "aws_vpc" "inspection_vpc" {
  cidr_block = var.cidr
  #   ipv4_ipam_pool_id   = var.ipv4_ipam_pool_id
  #   ipv4_netmask_length = var.ipv4_netmask_length

  #   assign_generated_ipv6_cidr_block     = var.enable_ipv6 && !var.use_ipam_pool ? true : null
  #   ipv6_cidr_block                      = var.ipv6_cidr
  #   ipv6_ipam_pool_id                    = var.ipv6_ipam_pool_id
  #   ipv6_netmask_length                  = var.ipv6_netmask_length
  #   ipv6_cidr_block_network_border_group = var.ipv6_cidr_block_network_border_group

  #instance_tenancy                     = var.instance_tenancy
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = true

  tags = merge(
    { "Name" = local.id },
    local.tags
  )
}

#-------------------------------------------------------------------------------
# Publiс Subnets
#-------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = local.len_public_subnets

  availability_zone    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block           = element(concat(var.public_subnets, [""]), count.index)
  #   enable_dns64                                   = var.enable_ipv6 && var.public_subnet_enable_dns64
  #   enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.public_subnet_enable_resource_name_dns_aaaa_record_on_launch
  #   enable_resource_name_dns_a_record_on_launch    = !var.public_subnet_ipv6_native && var.public_subnet_enable_resource_name_dns_a_record_on_launch
  #   ipv6_cidr_block                                = var.enable_ipv6 && length(var.public_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.inspection_vpc[0].ipv6_cidr_block, 8, var.public_subnet_ipv6_prefixes[count.index]) : null
  #   ipv6_native                                    = var.enable_ipv6 && var.public_subnet_ipv6_native
  #   map_public_ip_on_launch                        = var.map_public_ip_on_launch
  #   private_dns_hostname_type_on_launch            = var.public_subnet_private_dns_hostname_type_on_launch
  vpc_id = local.vpc_id

  tags = merge(
    {
      Name = format("${local.id}-${var.public_subnet_suffix}-%s", element(var.azs, count.index))
    },
    local.tags
  )
}

locals {
  num_public_route_tables = 1
}

resource "aws_route_table" "public" {
  count = local.len_public_subnets

  vpc_id = local.vpc_id

  tags = merge(
    {
      Name = format("${local.id}-${var.public_subnet_suffix}-%s", element(var.azs, count.index))
    },
    local.tags
  )
}

resource "aws_route_table_association" "public" {
  count = local.len_public_subnets

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = element(aws_route_table.public[*].id, count.index)
}

resource "aws_route" "public_internet_gateway" {
  count = local.len_public_subnets

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_to_firewall" {
  count = local.len_public_subnets

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = local.super_cidr_block
  # https://github.com/hashicorp/terraform-provider-aws/issues/16759
  vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.inspection_vpc_anfw[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.firewall[count.index].id], 0)

  timeouts {
    create = "5m"
  }
}
# resource "aws_route_table" "inspection_vpc_public_subnet_route_table" {
#   count  = length(data.aws_availability_zones.available.names)
#   vpc_id = aws_vpc.inspection_vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.inspection_vpc_igw.id
#   }
#   route {
#     cidr_block = var.super_cidr_block
#     # https://github.com/hashicorp/terraform-provider-aws/issues/16759
#     vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.inspection_vpc_anfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.inspection_vpc_firewall_subnet[count.index].id], 0)
#   }
#   tags = {
#     Name = "inspection-vpc/${data.aws_availability_zones.available.names[count.index]}/public-subnet-route-table"
#   }
# }

#-------------------------------------------------------------------------------
# firewall Subnets
#-------------------------------------------------------------------------------

locals {
  create_firewall_subnets = local.len_firewall_subnets > 0
}

resource "aws_subnet" "firewall" {
  count = local.create_firewall_subnets ? local.len_firewall_subnets : 0

  #   assign_ipv6_address_on_creation                = var.enable_ipv6 && var.private_subnet_ipv6_native ? true : var.private_subnet_assign_ipv6_address_on_creation
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block           = element(concat(var.firewall_subnets, [""]), count.index)
  #   enable_dns64                                   = var.enable_ipv6 && var.private_subnet_enable_dns64
  #   enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.private_subnet_enable_resource_name_dns_aaaa_record_on_launch
  #   enable_resource_name_dns_a_record_on_launch    = !var.private_subnet_ipv6_native && var.private_subnet_enable_resource_name_dns_a_record_on_launch
  #   ipv6_cidr_block                                = var.enable_ipv6 && length(var.private_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.inspection_vpc[0].ipv6_cidr_block, 8, var.private_subnet_ipv6_prefixes[count.index]) : null
  #   ipv6_native                                    = var.enable_ipv6 && var.private_subnet_ipv6_native
  #   private_dns_hostname_type_on_launch            = var.private_subnet_private_dns_hostname_type_on_launch
  vpc_id = local.vpc_id

  tags = merge(
    {
      Name = format("${local.id}-${var.firewall_subnet_suffix}-%s", element(var.azs, count.index))
    },
    local.tags
  )
}

# There are as many routing tables as the number of NAT gateways
resource "aws_route_table" "firewall" {
  count = local.create_firewall_subnets ? local.nat_gateway_count : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = var.single_nat_gateway ? "${local.id}-${var.firewall_subnet_suffix}" : format(
        "${local.id}-${var.firewall_subnet_suffix}-%s",
        element(var.azs, count.index),
      )
    },
    local.tags
  )
}

resource "aws_route_table_association" "firewall" {
  count = local.create_firewall_subnets ? local.len_firewall_subnets : 0

  subnet_id = element(aws_subnet.firewall[*].id, count.index)
  route_table_id = element(
    aws_route_table.firewall[*].id,
    var.single_nat_gateway ? 0 : count.index,
  )
}

resource "aws_route" "firewall_nat_gateway" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.firewall[*].id, count.index)
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}

# resource "aws_route" "firewall_to_transit_gateway" {
#   count = var.enable_nat_gateway ? local.nat_gateway_count : 0

#   route_table_id         = element(aws_route_table.firewall[*].id, count.index)
#   destination_cidr_block = local.super_cidr_block
#   #   transit_gateway_id = aws_ec2_transit_gateway.tgw.id

#   timeouts {
#     create = "5m"
#   }
# }

#-------------------------------------------------------------------------------
# transit_gateway Subnets
#-------------------------------------------------------------------------------

locals {
  create_transit_gateway_subnets     = local.len_transit_gateway_subnets > 0
  create_transit_gateway_route_table = local.create_transit_gateway_subnets
}

resource "aws_subnet" "transit_gateway" {
  count = local.create_transit_gateway_subnets ? local.len_transit_gateway_subnets : 0

  #   assign_ipv6_address_on_creation                = var.enable_ipv6 && var.transit_gateway_subnet_ipv6_native ? true : var.transit_gateway_subnet_assign_ipv6_address_on_creation
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block           = element(concat(var.transit_gateway_subnets, [""]), count.index)
  #   enable_dns64                                   = var.enable_ipv6 && var.transit_gateway_subnet_enable_dns64
  #   enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.transit_gateway_subnet_enable_resource_name_dns_aaaa_record_on_launch
  #   enable_resource_name_dns_a_record_on_launch    = !var.transit_gateway_subnet_ipv6_native && var.transit_gateway_subnet_enable_resource_name_dns_a_record_on_launch
  #   ipv6_cidr_block                                = var.enable_ipv6 && length(var.transit_gateway_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.inspection_vpc[0].ipv6_cidr_block, 8, var.transit_gateway_subnet_ipv6_prefixes[count.index]) : null
  #   ipv6_native                                    = var.enable_ipv6 && var.transit_gateway_subnet_ipv6_native
  #   private_dns_hostname_type_on_launch            = var.transit_gateway_subnet_private_dns_hostname_type_on_launch
  vpc_id = local.vpc_id

  tags = merge(
    {
      Name = format("${local.id}-${var.transit_gateway_subnet_suffix}-%s", element(var.azs, count.index), )

    },
    local.tags,
  )
}

# resource "aws_db_subnet_group" "transit_gateway" {
#   count = local.create_transit_gateway_subnets ? 1 : 0

#   name        = local.id
#   description = "Transit gateway subnet group for ${local.id}"
#   subnet_ids  = aws_subnet.transit_gateway[*].id

#   tags = merge(
#     {
#       "Name" = lower(local.id)
#     },
#     local.tags
#   )
# }

resource "aws_route_table" "transit_gateway" {
  count = local.create_transit_gateway_route_table ? var.single_nat_gateway ? 1 : local.len_transit_gateway_subnets : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = var.single_nat_gateway ? "${local.id}-${var.transit_gateway_subnet_suffix}" : format(
        "${local.id}-${var.transit_gateway_subnet_suffix}-%s",
        element(var.azs, count.index),
      )
    },
    local.tags
  )
}

resource "aws_route_table_association" "transit_gateway" {
  count = local.create_transit_gateway_subnets ? local.len_transit_gateway_subnets : 0

  subnet_id = element(aws_subnet.transit_gateway[*].id, count.index)
  route_table_id = element(
    coalescelist(aws_route_table.transit_gateway[*].id, aws_route_table.firewall[*].id),
    count.index,
  )
}

# resource "aws_route" "transit_gateway_internet_gateway" {
#   count = local.create_transit_gateway_route_table ? 1 : 0

#   route_table_id         = aws_route_table.transit_gateway[0].id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.this[0].id

#   timeouts {
#     create = "5m"
#   }
# }

resource "aws_route" "transit_gateway_firewall" {
  count = var.enable_nat_gateway && local.create_transit_gateway_route_table ? local.len_transit_gateway_subnets : 0

  route_table_id         = element(aws_route_table.transit_gateway[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"

  # https://github.com/hashicorp/terraform-provider-aws/issues/16759
  vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.inspection_vpc_anfw[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.firewall[count.index].id], 0)


  timeouts {
    create = "5m"
  }
}

# resource "aws_route" "transit_gateway_dns64_nat_gateway" {
#   count = local.create_transit_gateway_route_table && !var.create_transit_gateway_internet_gateway_route && var.create_transit_gateway_nat_gateway_route && var.enable_nat_gateway && var.enable_ipv6 && var.private_subnet_enable_dns64 ? var.single_nat_gateway ? 1 : local.len_transit_gateway_subnets : 0

#   route_table_id              = element(aws_route_table.transit_gateway[*].id, count.index)
#   destination_ipv6_cidr_block = "64:ff9b::/96"
#   nat_gateway_id              = element(aws_nat_gateway.this[*].id, count.index)

#   timeouts {
#     create = "5m"
#   }
# }

# resource "aws_route" "transit_gateway_ipv6_egress" {
#   count = local.create_transit_gateway_route_table && var.create_egress_only_igw && var.enable_ipv6 && var.create_transit_gateway_internet_gateway_route ? 1 : 0

#   route_table_id              = aws_route_table.transit_gateway[0].id
#   destination_ipv6_cidr_block = "::/0"
#   egress_only_gateway_id      = aws_egress_only_internet_gateway.this[0].id

#   timeouts {
#     create = "5m"
#   }
# }

#-------------------------------------------------------------------------------
# Internet Gateway
#-------------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  count = local.len_public_subnets > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = local.id },
    local.tags
  )
}

#-------------------------------------------------------------------------------
# NAT Gateway
#-------------------------------------------------------------------------------

locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : length(var.azs)
  nat_gateway_ips   = aws_eip.nat[*].id
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(
    {
      "Name" = format(
        "${local.id}-%s",
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    local.tags
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = element(
    aws_subnet.public[*].id,
    var.single_nat_gateway ? 0 : count.index,
  )

  tags = merge(
    {
      "Name" = format(
        "${local.id}-%s",
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    local.tags
  )

  depends_on = [aws_internet_gateway.this]
}

