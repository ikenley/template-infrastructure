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

variable "create_globals" {
  description = "Whether to create global resources e.g. IAM roles"
}

variable "agent_resource_role_arn" {
  default = ""
}
variable "agent_resource_role_name" {
  default = ""
}

variable "knowledge_base_role_arn" {
  default = ""
}
variable "knowledge_base_role_name" {
  default = ""
}
