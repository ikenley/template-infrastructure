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
  default = ""
}