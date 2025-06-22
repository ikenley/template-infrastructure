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

variable "project_name" {
  description = "Project name to use as a base for most resources"
}

variable "is_prod" {
  description = ""
  type        = bool
}

variable "domain_name" {}
variable "route_53_zone_id" {}

