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

variable "is_prod" {
  description = ""
  type = bool
}

# VPC

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

# DB
variable "instance_class" {}
variable "allocated_storage" {}
variable "max_allocated_storage" {}
variable "default_db_name" {}

variable "app_username" {
  description = "Username for the application user"
}

variable "data_lake_s3_bucket_name" {
  description = "Bucket name used for data lake ETL"
}