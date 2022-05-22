# ------------------------------------------------------------------------------
# Bastion host for connecting to private VPC resources
# ------------------------------------------------------------------------------

locals {
  id         = lower(join("-", [var.namespace, var.env, var.name, "bastion-host"]))
  key_prefix = "/${var.namespace}/${var.env}/${var.name}/bastion-host"
}

module "ec2_bastion" {
  source  = "cloudposse/ec2-bastion-server/aws"
  version = "0.30.0"

  name = local.id

  instance_type = "t3.micro"
  key_name      = module.aws_key_pair.key_name

  vpc_id                 = var.vpc_id
  subnets                = var.private_subnets
  security_group_enabled = false
  security_groups        = [module.bastion_host_sg.security_group_id]
}

module "bastion_host_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${local.id}-sg"
  description = "Security group for bastion host. Ingress is intentionally empty. Use SSM Session Manager."
  vpc_id      = var.vpc_id

  ingress_rules = []
  egress_rules  = ["all-all"]
}

# Default EC2 key pair
module "aws_key_pair" {
  source              = "cloudposse/key-pair/aws"
  version             = "0.16.1"
  attributes          = ["ssh", "key"]
  ssh_public_key_path = "~/.ssh"
  generate_ssh_key    = true
  name                = local.id
}
