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
variable "azs" {}

variable "public_subnets" {}
variable "public_subnet_suffix" {
  default = "public"
}

variable "firewall_subnets" {}
variable "firewall_subnet_suffix" {
  default = "firewall"
}

variable "transit_gateway_subnets" {}
variable "transit_gateway_subnet_suffix" {
  default = "transit_gateway"
}

variable "enable_nat_gateway" {
  type = bool
}
variable "single_nat_gateway" {
  default = false
}
variable "nat_gateway_destination_cidr_block" {
  default = "0.0.0.0/0"
}
