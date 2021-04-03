variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Project name to use as a base for most resources"
}

variable "env" {
  description = "Environment used for tagging images etc."
}

variable "is_prod" {
  description = ""
  type        = bool
}

variable "vpc_id" {
  description = "VPC to deploy resources into"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
}

# VPN

variable "server_certificate_arn" {
  description = "See README.md"
}

variable "root_certificate_chain_arn" {
  description = "See README.md"
}

variable "client_cidr_block" {
  description = "CIDR range to assign client connections. Must not be used by current subnets"
}

variable "subnet_id" {
  description = "Subnet to associate connections"
}


