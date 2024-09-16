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

variable "read_write_root_role_arns" {
  description = "List of IAM role ARNs which should have read/write access to NFS root"
}

variable "demo_app_access_point_role_arns" {
  description = "List of IAM role ARNS which should have read/write access to demo_app Access Point"
}
