
#-----------------------------------------------------------------------------
# main
#-----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  id            = "${var.namespace}-${var.env}-${var.name}-nat"
  output_prefix = "/${var.namespace}/${var.env}/${var.name}/nat"

  tags = merge(var.tags, {
    Environment = var.env
  })
}


// Create security groups that allows all traffic from VPC's cidr to NAT-Instance.
resource "aws_security_group" "nat_instance_sg" {
  vpc_id = var.aws_vpc_id
  name   = "${local.id}-instance"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "all"
    cidr_blocks     = [data.aws_vpc.current_vpc.cidr_block]
    prefix_list_ids = []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.id}-sg-nat-instance"
  }
}

// Create role.
resource "aws_iam_role" "ssm_agent_role" {
  name = "${local.id}-iam-role-ssm-agent"
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
  policy_arn = var.ssm_agent_policy
  role       = aws_iam_role.ssm_agent_role.name
}

// Create instance profile.
resource "aws_iam_instance_profile" "nat_instance_profile" {
  name = "${local.id}-iam-profile-nat-instance"
  role = aws_iam_role.ssm_agent_role.name
}

resource "aws_network_interface" "network_interface" {
  source_dest_check = false
  subnet_id         = var.public_subnets_ids[0]
  security_groups   = [aws_security_group.nat_instance_sg.id]

  tags = {
    Name = "${local.id}-nat-instance-network-interface"
  }
}

// Route private networks through NAT-Instance network interface.
resource "aws_route" "route_to_nat_instace" {
  destination_cidr_block = "0.0.0.0/0"
  count                  = var.number_of_azs
  network_interface_id   = aws_network_interface.network_interface.id
  route_table_id         = tolist(var.private_route_table_ids)[count.index]
}

resource "tls_private_key" "nat_instance_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "nat_instance_key_pair" {
  key_name   = "${local.id}-ec2-nat-instance"
  public_key = tls_private_key.nat_instance_private_key.public_key_openssh
}

resource "aws_ssm_parameter" "nat_instance_ssm" {
  name        = "${local.output_prefix}/ec2-nat-instance/key"
  description = "${local.id}-ec2-nat-instance ssh key"
  type        = "SecureString"
  value       = tls_private_key.nat_instance_private_key.private_key_pem

  tags = local.tags
}

// Creating NAT Instance.
resource "aws_instance" "nat_instance" {
  // Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs.
  instance_type        = var.nat_instance_type
  key_name             = aws_key_pair.nat_instance_key_pair.key_name
  ami                  = data.aws_ami.amazon_linux.id
  iam_instance_profile = aws_iam_instance_profile.nat_instance_profile.name
  user_data            = data.template_file.nat_instance_setup_template.rendered

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.network_interface.id
  }

  tags = merge(local.tags, {
    Name = "${local.id}-ec2-nat-instance"
  })
}
