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

# DNS
variable "parent_domain_name" {}

variable "domain_name" {
  description = "Base domain name e.g. example.com"
}

variable "path_prefix" {
  default     = ""
  description = "Default path prefix for site e.g. my-prefix"
}

variable "logs_bucket_name" {}

variable "create_index_html_function" {
  type    = bool
  default = false
}
