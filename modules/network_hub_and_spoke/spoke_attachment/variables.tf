variable "super_cidr_block" {
  type    = string
  default = "10.0.0.0/8"
}

locals {
  spoke_vpc_a_cidr    = cidrsubnet(var.super_cidr_block, 8, 10)
  spoke_vpc_b_cidr    = cidrsubnet(var.super_cidr_block, 8, 11)
  inspection_vpc_cidr = cidrsubnet(var.super_cidr_block, 8, 255)
}

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

variable "is_prod" {
  description = ""
  type        = bool
}

variable "project" {
  description = "Project name to use as a base for most resources"
}


# For the following vars, see:
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest?tab=inputs
variable "cidr" {}
variable "availability_zones" {}

variable "enable_nat_gateway" {
  type = bool
}
variable "single_nat_gateway" {
  default = false
}
variable "nat_gateway_destination_cidr_block" {
  default = "0.0.0.0/0"
}
