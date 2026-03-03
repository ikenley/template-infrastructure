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

variable "create_acm_certificate" {
  type = bool
}
variable "acm_certificate_arn" {
  default     = null
  description = "ACM certificate ARN. If none is passed, a new cert will be created"
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

variable "viewer_request_function_arn" {
  type        = string
  default     = null
  description = "ARN of an externally-defined CloudFront Function to associate with viewer-request on the default cache behavior. Takes precedence over create_index_html_function."
}

# Configuration for additional origins
# This is currently optimized for adding an API Gateway backend
variable "additional_origins" {
  type = map(object({
    domain_name  = string
    path_pattern = string
  }))
  default = {}
}
