variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "namespace" {
  description = "Project name to use as a base for most resources"
}

variable "env" {
  description = "Environment used for tagging images etc."
}

variable "name" {
  description = "Project name to use as a base for most resources"
}

# DNS
# variable "domain_name" {
#   description = "Base domain name e.g. example.com"
# }

variable "vpc_id" {}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}
