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

# Dynamo DB config 
variable "name" {}

variable "read_capacity" {
  default = 1
}

variable "write_capacity" {
  default = 1
}

variable "hash_key" {}
variable "hash_key_type" {
  default = "S"
}

variable "range_key" {
  default = ""
}
variable "range_key_type" {
  default = ""
}

variable "role_name" {

}


