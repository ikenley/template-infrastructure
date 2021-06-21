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

variable "range_key" {
  default = ""
}

variable "attributes" {
  type    = list(any)
  default = []
}

variable "role_name" {

}



