variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Project name to use as a base for most resources"
}

variable "env" {
  description = "Environment used for tagging images etc."
}

variable "vpc_id" {
  description = "VPC to deploy resources into"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type = list(string)
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

# DNS

variable "domain_name" {
  description = "Base domain name e.g. example.com"
}

variable "dns_subdomain" {
  description = "Subdomain for creating a record e.g. my-subdomain"
}

# ECS Task Definition

variable "container_name" {
  description = "Name of the running container"
}

variable "container_memory" {
  type        = number
  description = "The amount of memory (in MiB) to allow the container to use. This is a hard limit, if the container attempts to exceed the container_memory, the container is killed."
  default     = null
}

variable "container_cpu" {
  type        = number
  description = "The number of cpu units to reserve for the container."
  default     = 0
}

# ECS Service

variable "desired_count" {
  description = "(Optional) The number of instances of the task definition to place and keep running. Defaults to 0."
  type        = number
  default     = 1
}

variable "security_groups" {
  description = "(Optional) The security groups associated with the task or service. If you do not specify a security group, the default security group for the VPC is used."
  type        = list(any)
  default     = []
}

# CodePipeline

variable "code_pipeline_s3_bucket_name" {}
variable "source_full_repository_id" {}
variable "source_branch_name" {}
variable "codestar_connection_arn" {}
