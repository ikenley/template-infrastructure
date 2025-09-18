variable "super_cidr_block" {
  type    = string
  default = "10.0.0.0/8"
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
variable "hub_vpc_cidr" {}
variable "availability_zones" {}

variable "enable_nat_gateway" {
  type = bool
}
variable "single_nat_gateway" {
  default = false
}

variable "spoke_vpc_cidrs" {
  type = set(string)
}
