# #-------------------------------------------------------------------------------
# # Core VPC setup
# # Fork of: https://github.com/terraform-aws-modules/terraform-aws-vpc
# #-------------------------------------------------------------------------------

# locals {
#   vpc_id = aws_vpc.this.id

#   len_public_subnets   = length(var.public_subnets)
#   len_private_subnets  = length(var.private_subnets)
#   len_database_subnets = length(var.database_subnets)
# }

# resource "aws_vpc" "this" {
#   cidr_block = var.cidr
#   #   ipv4_ipam_pool_id   = var.ipv4_ipam_pool_id
#   #   ipv4_netmask_length = var.ipv4_netmask_length

#   #   assign_generated_ipv6_cidr_block     = var.enable_ipv6 && !var.use_ipam_pool ? true : null
#   #   ipv6_cidr_block                      = var.ipv6_cidr
#   #   ipv6_ipam_pool_id                    = var.ipv6_ipam_pool_id
#   #   ipv6_netmask_length                  = var.ipv6_netmask_length
#   #   ipv6_cidr_block_network_border_group = var.ipv6_cidr_block_network_border_group

#   #instance_tenancy                     = var.instance_tenancy
#   enable_dns_hostnames                 = true
#   enable_dns_support                   = true
#   enable_network_address_usage_metrics = true

#   tags = merge(
#     { "Name" = local.id },
#     local.tags
#   )
# }

# ################################################################################
# # Publiс Subnets
# ################################################################################

# resource "aws_subnet" "public" {
#   count = local.len_public_subnets

#   availability_zone    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
#   availability_zone_id = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
#   cidr_block           = element(concat(var.public_subnets, [""]), count.index)
#   #   enable_dns64                                   = var.enable_ipv6 && var.public_subnet_enable_dns64
#   #   enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.public_subnet_enable_resource_name_dns_aaaa_record_on_launch
#   #   enable_resource_name_dns_a_record_on_launch    = !var.public_subnet_ipv6_native && var.public_subnet_enable_resource_name_dns_a_record_on_launch
#   #   ipv6_cidr_block                                = var.enable_ipv6 && length(var.public_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.public_subnet_ipv6_prefixes[count.index]) : null
#   #   ipv6_native                                    = var.enable_ipv6 && var.public_subnet_ipv6_native
#   #   map_public_ip_on_launch                        = var.map_public_ip_on_launch
#   #   private_dns_hostname_type_on_launch            = var.public_subnet_private_dns_hostname_type_on_launch
#   vpc_id = local.vpc_id

#   tags = merge(
#     {
#       Name = format("${local.id}-${var.public_subnet_suffix}-%s", element(var.azs, count.index))
#     },
#     local.tags
#   )
# }

# locals {
#   num_public_route_tables = 1
# }

# resource "aws_route_table" "public" {
#   count = local.len_public_subnets > 0 ? 1 : 0

#   vpc_id = local.vpc_id

#   tags = merge(
#     {
#       "Name" : "${local.id}}-${var.public_subnet_suffix}"
#     },
#     local.tags
#   )
# }

# resource "aws_route_table_association" "public" {
#   count = local.len_public_subnets > 0 ? 1 : 0

#   subnet_id      = element(aws_subnet.public[*].id, count.index)
#   route_table_id = element(aws_route_table.public[*].id, 0)
# }

# resource "aws_route" "public_internet_gateway" {
#   count = local.len_public_subnets > 0 ? 1 : 0

#   route_table_id         = aws_route_table.public[count.index].id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.this[0].id

#   timeouts {
#     create = "5m"
#   }
# }

# ################################################################################
# # Private Subnets
# ################################################################################

# locals {
#   create_private_subnets = local.len_private_subnets > 0
# }

# resource "aws_subnet" "private" {
#   count = local.create_private_subnets ? local.len_private_subnets : 0

#   #   assign_ipv6_address_on_creation                = var.enable_ipv6 && var.private_subnet_ipv6_native ? true : var.private_subnet_assign_ipv6_address_on_creation
#   availability_zone    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
#   availability_zone_id = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
#   cidr_block           = element(concat(var.private_subnets, [""]), count.index)
#   #   enable_dns64                                   = var.enable_ipv6 && var.private_subnet_enable_dns64
#   #   enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.private_subnet_enable_resource_name_dns_aaaa_record_on_launch
#   #   enable_resource_name_dns_a_record_on_launch    = !var.private_subnet_ipv6_native && var.private_subnet_enable_resource_name_dns_a_record_on_launch
#   #   ipv6_cidr_block                                = var.enable_ipv6 && length(var.private_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.private_subnet_ipv6_prefixes[count.index]) : null
#   #   ipv6_native                                    = var.enable_ipv6 && var.private_subnet_ipv6_native
#   #   private_dns_hostname_type_on_launch            = var.private_subnet_private_dns_hostname_type_on_launch
#   vpc_id = local.vpc_id

#   tags = merge(
#     {
#       Name = format("${local.id}-${var.private_subnet_suffix}-%s", element(var.azs, count.index))
#     },
#     local.tags
#   )
# }

# # There are as many routing tables as the number of NAT gateways
# resource "aws_route_table" "private" {
#   count = local.create_private_subnets ? local.nat_gateway_count : 0

#   vpc_id = local.vpc_id

#   tags = merge(
#     {
#       "Name" = var.single_nat_gateway ? "${local.id}-${var.private_subnet_suffix}" : format(
#         "${local.id}-${var.private_subnet_suffix}-%s",
#         element(var.azs, count.index),
#       )
#     },
#     local.tags
#   )
# }

# resource "aws_route_table_association" "private" {
#   count = local.create_private_subnets ? local.len_private_subnets : 0

#   subnet_id = element(aws_subnet.private[*].id, count.index)
#   route_table_id = element(
#     aws_route_table.private[*].id,
#     var.single_nat_gateway ? 0 : count.index,
#   )
# }

# ################################################################################
# # Database Subnets
# ################################################################################

# locals {
#   create_database_subnets     = local.len_database_subnets > 0
#   create_database_route_table = local.create_database_subnets
# }

# resource "aws_subnet" "database" {
#   count = local.create_database_subnets ? local.len_database_subnets : 0

#   #   assign_ipv6_address_on_creation                = var.enable_ipv6 && var.database_subnet_ipv6_native ? true : var.database_subnet_assign_ipv6_address_on_creation
#   availability_zone    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
#   availability_zone_id = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
#   cidr_block           = element(concat(var.database_subnets, [""]), count.index)
#   #   enable_dns64                                   = var.enable_ipv6 && var.database_subnet_enable_dns64
#   #   enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.database_subnet_enable_resource_name_dns_aaaa_record_on_launch
#   #   enable_resource_name_dns_a_record_on_launch    = !var.database_subnet_ipv6_native && var.database_subnet_enable_resource_name_dns_a_record_on_launch
#   #   ipv6_cidr_block                                = var.enable_ipv6 && length(var.database_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.database_subnet_ipv6_prefixes[count.index]) : null
#   #   ipv6_native                                    = var.enable_ipv6 && var.database_subnet_ipv6_native
#   #   private_dns_hostname_type_on_launch            = var.database_subnet_private_dns_hostname_type_on_launch
#   vpc_id = local.vpc_id

#   tags = merge(
#     {
#       Name = format("${local.id}-${var.database_subnet_suffix}-%s", element(var.azs, count.index), )

#     },
#     local.tags,
#   )
# }

# resource "aws_db_subnet_group" "database" {
#   count = local.create_database_subnets ? 1 : 0

#   name        = local.id
#   description = "Database subnet group for ${local.id}"
#   subnet_ids  = aws_subnet.database[*].id

#   tags = merge(
#     {
#       "Name" = lower(local.id)
#     },
#     local.tags
#   )
# }

# resource "aws_route_table" "database" {
#   count = local.create_database_route_table ? var.single_nat_gateway ? 1 : local.len_database_subnets : 0

#   vpc_id = local.vpc_id

#   tags = merge(
#     {
#       "Name" = var.single_nat_gateway ? "${local.id}-${var.database_subnet_suffix}" : format(
#         "${local.id}-${var.database_subnet_suffix}-%s",
#         element(var.azs, count.index),
#       )
#     },
#     local.tags
#   )
# }

# resource "aws_route_table_association" "database" {
#   count = local.create_database_subnets ? local.len_database_subnets : 0

#   subnet_id = element(aws_subnet.database[*].id, count.index)
#   route_table_id = element(
#     coalescelist(aws_route_table.database[*].id, aws_route_table.private[*].id),
#     count.index,
#   )
# }

# # resource "aws_route" "database_internet_gateway" {
# #   count = local.create_database_route_table ? 1 : 0

# #   route_table_id         = aws_route_table.database[0].id
# #   destination_cidr_block = "0.0.0.0/0"
# #   gateway_id             = aws_internet_gateway.this[0].id

# #   timeouts {
# #     create = "5m"
# #   }
# # }

# # resource "aws_route" "database_nat_gateway" {
# #   count = local.create_database_route_table && !var.create_database_internet_gateway_route && var.create_database_nat_gateway_route && var.enable_nat_gateway ? var.single_nat_gateway ? 1 : local.len_database_subnets : 0

# #   route_table_id         = element(aws_route_table.database[*].id, count.index)
# #   destination_cidr_block = "0.0.0.0/0"
# #   nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

# #   timeouts {
# #     create = "5m"
# #   }
# # }

# # resource "aws_route" "database_dns64_nat_gateway" {
# #   count = local.create_database_route_table && !var.create_database_internet_gateway_route && var.create_database_nat_gateway_route && var.enable_nat_gateway && var.enable_ipv6 && var.private_subnet_enable_dns64 ? var.single_nat_gateway ? 1 : local.len_database_subnets : 0

# #   route_table_id              = element(aws_route_table.database[*].id, count.index)
# #   destination_ipv6_cidr_block = "64:ff9b::/96"
# #   nat_gateway_id              = element(aws_nat_gateway.this[*].id, count.index)

# #   timeouts {
# #     create = "5m"
# #   }
# # }

# # resource "aws_route" "database_ipv6_egress" {
# #   count = local.create_database_route_table && var.create_egress_only_igw && var.enable_ipv6 && var.create_database_internet_gateway_route ? 1 : 0

# #   route_table_id              = aws_route_table.database[0].id
# #   destination_ipv6_cidr_block = "::/0"
# #   egress_only_gateway_id      = aws_egress_only_internet_gateway.this[0].id

# #   timeouts {
# #     create = "5m"
# #   }
# # }

# ################################################################################
# # Internet Gateway
# ################################################################################

# resource "aws_internet_gateway" "this" {
#   count = local.len_public_subnets > 0 ? 1 : 0

#   vpc_id = local.vpc_id

#   tags = merge(
#     { "Name" = local.id },
#     local.tags
#   )
# }

# ################################################################################
# # NAT Gateway
# ################################################################################

# locals {
#   nat_gateway_count = var.single_nat_gateway ? 1 : length(var.azs)
#   nat_gateway_ips   = aws_eip.nat[*].id
# }

# resource "aws_eip" "nat" {
#   count = var.enable_nat_gateway ? local.nat_gateway_count : 0

#   domain = "vpc"

#   tags = merge(
#     {
#       "Name" = format(
#         "${local.id}-%s",
#         element(var.azs, var.single_nat_gateway ? 0 : count.index),
#       )
#     },
#     local.tags
#   )

#   depends_on = [aws_internet_gateway.this]
# }

# resource "aws_nat_gateway" "this" {
#   count = var.enable_nat_gateway ? local.nat_gateway_count : 0

#   allocation_id = element(
#     local.nat_gateway_ips,
#     var.single_nat_gateway ? 0 : count.index,
#   )
#   subnet_id = element(
#     aws_subnet.public[*].id,
#     var.single_nat_gateway ? 0 : count.index,
#   )

#   tags = merge(
#     {
#       "Name" = format(
#         "${local.id}-%s",
#         element(var.azs, var.single_nat_gateway ? 0 : count.index),
#       )
#     },
#     local.tags
#   )

#   depends_on = [aws_internet_gateway.this]
# }

# resource "aws_route" "private_nat_gateway" {
#   count = var.enable_nat_gateway ? local.nat_gateway_count : 0

#   route_table_id         = element(aws_route_table.private[*].id, count.index)
#   destination_cidr_block = var.nat_gateway_destination_cidr_block
#   nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

#   timeouts {
#     create = "5m"
#   }
# }

