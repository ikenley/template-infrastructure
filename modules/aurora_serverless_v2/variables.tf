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

variable "name" {
  description = "Resource name suffix"
}

variable "is_prod" {
  description = "Whether this is a production environment"
  type        = bool
}

# VPC

variable "vpc_id" {
  description = "VPC to deploy resources into"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "database_subnets" {
  description = "A list of database subnets"
  type        = list(string)
  default     = []
}

# DB

variable "database_name" {
  description = "Name of the default database (ignored when restoring from snapshot)"
  default     = "main"
}

variable "snapshot_identifier" {
  description = "ARN or identifier of the DB cluster snapshot to restore from. Null creates a fresh cluster."
  type        = string
  default     = null
}

variable "min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity in ACUs (0.5 ACU increments)"
  type        = number
  default     = 0
}

variable "max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity in ACUs"
  type        = number
  default     = 4
}

variable "backup_retention_period" {
  description = "Days to retain automated backups"
  type        = number
  default     = 1
}
