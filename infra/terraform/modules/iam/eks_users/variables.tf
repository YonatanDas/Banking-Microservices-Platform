variable "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/stag/prod)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming resources (e.g., 'banking' or '' for no prefix)"
  type        = string
  default     = ""
}


variable "users" {
  description = "Map of users to create with their group assignments. Format: { username = { groups = [\"developers\", \"viewers\"] } }"
  type = map(object({
    groups = list(string)
  }))
  default = {}
}

variable "group_path" {
  description = "Path for IAM groups"
  type        = string
  default     = "/eks/"
}

