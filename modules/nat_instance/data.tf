// Get VPC data.
data "aws_vpc" "current_vpc" {
  id = var.aws_vpc_id
}

// Choosing the image for NAT Instance.
data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = [var.amazon_ec2_linux_image]
  }
  filter {
    name   = "virtualization-type"
    values = [var.amazon_ec2_instance_virtualization_type]
  }
  owners = [137112412989] # AWS
}

// Get NAT Instance data.
data "aws_instance" "nat_instance_data" {
  instance_id = aws_instance.nat_instance.id
}
