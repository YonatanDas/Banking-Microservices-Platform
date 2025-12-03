variable "env" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}
variable "oidc_provider_url" {
  type = string
}

variable "secretsmanager_arns" {
  description = "ARNs of Secrets Manager secrets ESO can read"
  type        = list(string)
}
