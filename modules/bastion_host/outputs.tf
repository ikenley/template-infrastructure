# VPC
resource "aws_ssm_parameter" "bastion_host_instance_id" {
  name  = "${local.key_prefix}/instance-id"
  type  = "String"
  value = module.ec2_bastion.instance_id
}

output "bastion_host_instance_id" {
  value = module.ec2_bastion.instance_id
}

