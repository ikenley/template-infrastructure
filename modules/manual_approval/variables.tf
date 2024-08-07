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

variable "project" {
  description = "Project to use as a base for most resources"
}

variable "is_prod" {
  description = ""
  type        = bool
}

variable "ses_email_addresses" {
  type = set(string)
}

variable "sns_topic_arns" {
  type = list(string)
}
