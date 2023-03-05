

resource "aws_ssm_parameter" "revisit_prediction__pg_connection" {
  name  = "${local.output_prefix}/revisit_prediction/pg_connection"
  type  = "SecureString"
  value = "TODO"

  overwrite = false 

  # TODO populate this via data sources
  lifecycle {  
    ignore_changes = [value]
  }
}

# Used only for local dev
resource "aws_ssm_parameter" "revisit_prediction_local__pg_connection" {
  name  = "${local.output_prefix}/revisit_prediction_local/pg_connection"
  type  = "SecureString"
  value = "TODO"

  overwrite = false 

  # TODO populate this via data sources
  lifecycle {  
    ignore_changes = [value]
  }
}