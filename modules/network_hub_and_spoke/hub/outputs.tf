#------------------------------------------------------------------------------
# firewall.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "anfw_flow_bucket_id" {
  name  = "${local.output_prefix}/anfw_flow_bucket_id"
  type  = "String"
  value = module.anfw_flow_bucket.s3_bucket_id
}
output "anfw_flow_bucket_id" {
  value = module.anfw_flow_bucket.s3_bucket_id
}

#------------------------------------------------------------------------------
# hub_vpc.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "hub_vpc_id" {
  name  = "${local.output_prefix}/hub_vpc_id"
  type  = "String"
  value = aws_vpc.hub_vpc.id
}
output "hub_vpc_id" {
  value = aws_vpc.hub_vpc.id
}

resource "aws_ssm_parameter" "hub_vpc_cidr" {
  name  = "${local.output_prefix}/hub_vpc_cidr"
  type  = "String"
  value = aws_vpc.hub_vpc.cidr_block
}

resource "aws_ssm_parameter" "hub_vpc_public_subnets" {
  name  = "${local.output_prefix}/hub_vpc_public_subnets"
  type  = "String"
  value = join(",", aws_subnet.hub_vpc_public_subnet[*].id)
}

resource "aws_ssm_parameter" "hub_vpc_firewall_subnets" {
  name  = "${local.output_prefix}/hub_vpc_firewall_subnets"
  type  = "String"
  value = join(",", aws_subnet.hub_vpc_firewall_subnet[*].id)
}

resource "aws_ssm_parameter" "hub_vpc_transit_gateway_subnets" {
  name  = "${local.output_prefix}/hub_vpc_transit_gateway_subnets"
  type  = "String"
  value = join(",", aws_subnet.hub_vpc_tgw_subnet[*].id)
}

#------------------------------------------------------------------------------
# transit_gateway.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "transit_gateway_arn" {
  name  = "${local.output_prefix}/transit_gateway_arn"
  type  = "String"
  value = aws_ec2_transit_gateway.tgw.arn
}

resource "aws_ssm_parameter" "transit_gateway_id" {
  name  = "${local.output_prefix}/transit_gateway_id"
  type  = "String"
  value = aws_ec2_transit_gateway.tgw.id
}
output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.tgw.id
}
