variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "namespace" {
  description = "Project namespace to use as a base for most resources"
}

variable "env" {
  description = "Environment used for tagging images etc."
}

variable "name" {
  description = "Project name to use as a base for most resources"
}

variable "amazon_ec2_linux_image" {
  description = "Amazon linux image for NAT instance."
  type        = string
  default     = "amzn2-ami-kernel-5.10-hvm-*"
}

variable "amazon_ec2_instance_virtualization_type" {
  description = "Amazon linux image for NAT instance."
  type        = string
  default     = "hvm"
}

variable "ssm_agent_policy" {
  description = "Policy of SSM agent."
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

variable "aws_vpc_id" {
  type = string
}

variable "nat_instance_type" {
  type = string
}

variable "number_of_azs" {
  type = number
}

variable "public_subnets_ids" {}

variable "private_route_table_ids" {}
