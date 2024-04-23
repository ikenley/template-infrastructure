variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "bucket_name_suffix" {
  description = "S3 bucket name to append after the AWS account id"
}

variable "kms_alias" {
  description = "Optional key alias. By default uses standard AES encryption with no key"
  default     = ""
}

variable "bucket_policy" {
  description = "Optional bucket policy to override default"
  default     = ""
}

variable "skip_create_policy" {
  description = "Skip creation of bucket policy. Useful for when this is overridden by other modules"
  type        = bool
  default     = false
}

variable "enable_archive" {
  description = "Whether to enable archive policy"
  type        = bool
  default     = false
}
