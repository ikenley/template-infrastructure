#-----------------------------------------------------------------------------
# A simple EC2 instance. Used to test network from the inside.
# If this were a "real" EC2 instance, it would be in a TF module. 
# ...but let us not make perfect the enemy of the good
#-----------------------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  test_instance               = "${local.namespace}-${local.env}-${local.project}-test-instance"
  test_instance_output_prefix = "/${local.namespace}/${local.env}/${local.project}/test-instance"

  tags = {
    Environment = local.env
  }
}


// Create security groups that allows all traffic from VPC's cidr to NAT-Instance.
resource "aws_security_group" "nat_instance_sg" {
  vpc_id = module.network_hub.vpc_id
  name   = "${local.test_instance}-instance"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "all"
    cidr_blocks     = [module.network_hub.vpc_cidr_block]
    prefix_list_ids = []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.test_instance}-sg"
  }
}

// Create role.
resource "aws_iam_role" "ssm_agent_role" {
  name = "${local.test_instance}-iam-role-ssm-agent"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : {
      "Effect" : "Allow",
      "Principal" : { "Service" : "ec2.amazonaws.com" },
      "Action" : "sts:AssumeRole"
    }
  })
}

// Attach role to policy.
resource "aws_iam_role_policy_attachment" "attach_ssm_role" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_agent_role.name
}

// Create instance profile.
resource "aws_iam_instance_profile" "nat_instance_profile" {
  name = "${local.test_instance}-iam-profilelocal."
  role = aws_iam_role.ssm_agent_role.name
}

resource "aws_network_interface" "network_interface" {
  source_dest_check = false
  subnet_id         = module.network_hub.private_subnets[0]
  security_groups   = [aws_security_group.nat_instance_sg.id]

  tags = {
    Name = "${local.test_instance}-network-interface"
  }
}

# // Route private networks through NAT-Instance network interface.
# resource "aws_route" "route_to_nat_instace" {
#   destination_cidr_block = "0.0.0.0/0"
#   count                  = var.number_of_azs
#   network_interface_id   = aws_network_interface.network_interface.id
#   route_table_id         = tolist(var.private_route_table_ids)[count.index]
# }

resource "tls_private_key" "nat_instance_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "nat_instance_key_pair" {
  key_name   = "${local.test_instance}-ec2"
  public_key = tls_private_key.nat_instance_private_key.public_key_openssh
}

resource "aws_ssm_parameter" "nat_instance_ssm" {
  name        = "${local.test_instance_output_prefix}/ec2/key"
  description = "${local.test_instance}-ec2 ssh key"
  type        = "SecureString"
  value       = tls_private_key.nat_instance_private_key.private_key_pem

  tags = local.tags
}

// Creating NAT Instance.
resource "aws_instance" "nat_instance" {
  count = local.spend_money ? 1 : 0

  // Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs.
  instance_type        = "t3.nano"
  key_name             = aws_key_pair.nat_instance_key_pair.key_name
  ami                  = data.aws_ami.amazon_linux.id
  iam_instance_profile = aws_iam_instance_profile.nat_instance_profile.name
  #user_data            = data.template_file.nat_instance_setup_template.rendered

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.network_interface.id
  }

  tags = merge(local.tags, {
    Name = "${local.test_instance}-ec2"
  })
}
