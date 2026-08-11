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

variable "alarm_emails" {
  description = "Email addresses subscribed to ai_app alarm notifications (e.g. job runner DLQ)"
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Project name to use as a base for most resources"
}

variable "git_repo" {}
variable "git_branch" {}

variable "description" {}

# DNS
variable "parent_domain_name" {}
variable "domain_name" {
  description = "domain name e.g. example.com"
}
