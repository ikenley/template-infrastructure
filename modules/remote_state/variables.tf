variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "s3_bucket_suffix" {
  description = "Suffix to append to bucket name e.g. dev"
}