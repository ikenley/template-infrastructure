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

variable "transit_gateway_arn" {}
variable "transit_gateway_id" {}

variable "hub_transit_gateway_attachment_id" {}
variable "hub_transit_gateway_route_table_id" {}

variable "spoke_key" {
  description = "Identifier used to create resources"
}

variable "spoke_vpc" {
  type = object({
    id : string
    cidr : string
    transit_gateway_subnets : list(object({
      cidr : string
      availability_zone : string
    }))
  })
}
