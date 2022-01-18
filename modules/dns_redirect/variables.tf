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

variable "is_prod" {
  description = ""
  type        = bool
}

# DNS

variable "domain_name" {
  description = "Base domain name e.g. example.com"
}

variable "redirect_url" {
  description = "The URL to redirec the domain to"
}
