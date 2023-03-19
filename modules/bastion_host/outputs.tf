# VPC
resource "aws_ssm_parameter" "bastion_host_instance_id" {
  name  = "${local.key_prefix}/instance-id"
  type  = "String"
  value = module.ec2_bastion.instance_id
}

output "bastion_host_instance_id" {
  value = module.ec2_bastion.instance_id
}

resource "aws_ssm_parameter" "bastion_host_public_key" {
  name  = "${local.key_prefix}/bastion_host_public_key"
  type  = "String"
  value = module.aws_key_pair.public_key
}

resource "aws_ssm_parameter" "bastion_host_private_key" {
  name  = "${local.key_prefix}/bastion_host_private_key"
  type  = "String"
  value = module.aws_key_pair.private_key
}