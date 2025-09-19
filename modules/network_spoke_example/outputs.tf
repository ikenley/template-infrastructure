#-------------------------------------------------------------------------------
# vpc
#-------------------------------------------------------------------------------

output "vpc_id" {
  value = aws_vpc.spoke_vpc.id
}

output "transit_gw_subnet_ids" {
  value = aws_subnet.transit_gw_subnet[*].id
}
