resource "aws_ssm_parameter" "bastion_host_instance_id" {
  name  = "${local.key_prefix}/instance-id"
  type  = "SecureString"
  value = aws_instance.this.id
}

output "bastion_host_instance_id" {
  value = aws_instance.this.id
}

resource "aws_ssm_parameter" "bastion_host_public_key" {
  name  = "${local.key_prefix}/bastion_host_public_key"
  type  = "SecureString"
  value = tls_private_key.this.public_key_openssh
}

resource "aws_ssm_parameter" "bastion_host_private_key" {
  name  = "${local.key_prefix}/bastion_host_private_key"
  type  = "SecureString"
  value = tls_private_key.this.private_key_pem
}
