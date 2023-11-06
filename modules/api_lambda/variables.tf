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

variable "git_repo" {}
variable "git_branch" {}


# DNS
variable "parent_domain_name" {}

variable "domain_name" {
  description = "Base domain name e.g. example.com"
}

# Network config
variable "aws_lb_listener_rule_priority" {
  default = 25000
}

# Lambda config
variable "image_uri" {
  description = "Placeholder image URI. Typically the CI/CD system overrides this."
  default     = "924586450630.dkr.ecr.us-east-1.amazonaws.com/ik-dev-ai-lambda-test:0.0.6"
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Map of Lambda environment variables"
}

variable "lambda_description" {
  default = ""
}
variable "lambda_timeout" {
  default = 3
}
