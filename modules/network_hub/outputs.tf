#------------------------------------------------------------------------------
# todo.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "vpc_id" {
  name  = "${local.output_prefix}/vpc_id"
  type  = "String"
  value = aws_vpc.this.id
}
