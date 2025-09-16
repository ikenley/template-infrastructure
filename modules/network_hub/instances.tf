#-------------------------------------------------------------------------------
# Test instances used to validate the firewall configuration
#-------------------------------------------------------------------------------

resource "aws_security_group" "spoke_vpc_a_host_sg" {
  name        = "spoke-vpc-a/sg-host"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = aws_vpc.spoke_vpc_a.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      aws_vpc.spoke_vpc_a.cidr_block
      # , aws_vpc.spoke_vpc_b.cidr_block
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "spoke-vpc-a/sg-host"
  }
}

# resource "aws_security_group" "spoke_vpc_b_host_sg" {
#   name        = "spoke-vpc-b/sg-host"
#   description = "Allow all traffic from VPCs inbound and all outbound"
#   vpc_id      = aws_vpc.spoke_vpc_b.id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = [aws_vpc.spoke_vpc_a.cidr_block, aws_vpc.spoke_vpc_b.cidr_block]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "spoke-vpc-b/sg-host"
#   }
# }

resource "aws_instance" "spoke_vpc_a_host" {
  ami                         = data.aws_ami.amazon-linux-2.id
  subnet_id                   = aws_subnet.spoke_vpc_a_protected_subnet[0].id
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  instance_type               = "t3.micro"
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.spoke_vpc_a_host_sg.id]
  tags = {
    Name = "spoke-vpc-a/host"
  }
}

# resource "aws_instance" "spoke_vpc_b_host" {
#   ami                    = data.aws_ami.amazon-linux-2.id
#   subnet_id              = aws_subnet.spoke_vpc_b_protected_subnet[0].id
#   iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
#   instance_type          = "t3.micro"
#   vpc_security_group_ids = [aws_security_group.spoke_vpc_b_host_sg.id]
#   tags = {
#     Name = "spoke-vpc-b/host"
#   }
#   user_data = file("install-nginx.sh")
# }

#-------------------------------------------------------------------------------
# Instance role
#-------------------------------------------------------------------------------

resource "aws_iam_role" "instance_role" {
  name               = "session-manager-instance-profile-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "session-manager-instance-profile"
  role = aws_iam_role.instance_role.name
}


resource "aws_iam_role_policy_attachment" "instance_role_policy_attachment" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


output "spoke_vpc_a_host_ip" {
  value = aws_instance.spoke_vpc_a_host.private_ip
}

# output "spoke_vpc_b_host_ip" {
#   value = aws_instance.spoke_vpc_b_host.private_ip
# }

