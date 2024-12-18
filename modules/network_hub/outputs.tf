#------------------------------------------------------------------------------
# vpc.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "vpc_id" {
  name  = "${local.output_prefix}/vpc_id"
  type  = "String"
  value = aws_vpc.this.id
}
output "vpc_id" {
  value = aws_vpc.this.id
}

resource "aws_ssm_parameter" "vpc_cidr_block" {
  name  = "${local.output_prefix}/vpc_cidr_block"
  type  = "String"
  value = try(aws_vpc.this.cidr_block, null)
}
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = try(aws_vpc.this.cidr_block, null)
}

resource "aws_ssm_parameter" "public_subnets" {
  name  = "${local.output_prefix}/public_subnets"
  type  = "String"
  value = join(",", aws_subnet.public[*].id)
}
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

resource "aws_ssm_parameter" "private_subnets" {
  name  = "${local.output_prefix}/private_subnets"
  type  = "String"
  value = join(",", aws_subnet.private[*].id)
}
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

resource "aws_ssm_parameter" "database_subnets" {
  name  = "${local.output_prefix}/database_subnets"
  type  = "String"
  value = join(",", aws_subnet.database[*].id)
}
output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}
