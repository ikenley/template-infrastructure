# ------------------------------------------------------------------------------
# Bastion host for connecting to private VPC resources via SSM Session Manager
# ------------------------------------------------------------------------------

locals {
  id         = lower(join("-", [var.namespace, var.env, var.name, "bastion-host"]))
  key_prefix = "/${var.namespace}/${var.env}/${var.name}/bastion-host"

  tags = merge(var.tags, {
    Environment = var.env
  })
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ------------------------------------------------------------------------------
# Security Group - no ingress; access via SSM Session Manager
# ------------------------------------------------------------------------------

module "bastion_host_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${local.id}-sg"
  description = "Security group for bastion host. Ingress is intentionally empty. Use SSM Session Manager."
  vpc_id      = var.vpc_id

  ingress_rules = []
  egress_rules  = ["all-all"]
}

# ------------------------------------------------------------------------------
# SSH Key Pair (backup access; primary access is SSM Session Manager)
# ------------------------------------------------------------------------------

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = local.id
  public_key = tls_private_key.this.public_key_openssh

  tags = local.tags
}

# ------------------------------------------------------------------------------
# IAM Role for SSM Session Manager
# ------------------------------------------------------------------------------

resource "aws_iam_role" "this" {
  name = "${local.id}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.this.name
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.id}-profile"
  role = aws_iam_role.this.name
}

# ------------------------------------------------------------------------------
# EC2 Instance
# ------------------------------------------------------------------------------

resource "aws_instance" "this" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.this.key_name
  iam_instance_profile   = aws_iam_instance_profile.this.name
  subnet_id              = var.private_subnets[0]
  vpc_security_group_ids = [module.bastion_host_sg.security_group_id]

  tags = merge(local.tags, {
    Name = local.id
  })
}
