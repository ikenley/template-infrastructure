variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Project name to use as a base for most resources"
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

variable "ecs_container_definitions" {
  description = "JSON container definitions https://docs.aws.amazon.com/cli/latest/reference/ecs/describe-task-definition.html"
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
