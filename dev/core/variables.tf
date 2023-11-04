variable "docker_password" {
  description = "Password for logging into DockerHub. STORE SECURELY. https://learn.hashicorp.com/tutorials/terraform/sensitive-variables"
  sensitive   = true
}

variable "spend_money" {
  type        = bool
  description = "Whether to enable expensive services that can be safely turned off and on"
  default     = false
}

# cognito
variable "google_client_id" {}
variable "google_client_secret" {}