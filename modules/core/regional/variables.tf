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

#------------------------------------------------------------------------------
# network
#------------------------------------------------------------------------------
variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
}

variable "dns_server_ip" {
  description = "The CIDR + 2 e.g. 10.0.0.2"
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "A list of database subnets"
  type        = list(string)
  default     = []
}

variable "vpc_client_cidr" {
  default = ""
}

variable "enable_s3_endpoint" {
  type = bool
}

# Bastion host

variable "enable_bastion_host" {
  type    = bool
  default = false
}

variable "enable_client_vpn" {
  type    = bool
  default = false
}

# Docker credentials

variable "docker_username" {
  description = "Username for logging into DockerHub"
  sensitive   = true
}

variable "docker_password" {
  description = "Password for logging into DockerHub. STORE SECURELY. https://learn.hashicorp.com/tutorials/terraform/sensitive-variables"
  sensitive   = true
}

# SES
variable "ses_email_address" {}

# CICD
variable "source_branch_name" {}

