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

variable "is_prod" {
  description = ""
  type        = bool
}

variable "spend_money" {
  description = "Disable expensive resources that are safe to destroy"
  type        = bool
}

variable "domain_name" {}
variable "route_53_zone_id" {}
