#------------------------------------------------------------------------------
# todo.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "todo" {
  name     = "${local.output_prefix}/todo"
  type     = "String"
  value    = "Open the pod bay doors, HAL"
}
