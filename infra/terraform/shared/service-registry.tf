# Service Registry
# This file defines the standard structure for service configurations
# Used across Terraform modules to dynamically configure microservices

# Service registry structure:
# map(object({
#   service_account_name = string
#   port                 = number
#   needs_rds_access     = bool
#   helm_name            = string  # Optional: if different from service name
# }))

# Example usage in environments:
# locals {
#   service_registry = var.service_registry
#   microservices = {
#     for k, v in local.service_registry : k => {
#       sa_name = v.service_account_name
#     }
#   }
# }

# This file serves as documentation and can be used to define default service configurations
# Actual service definitions should be in environment-specific tfvars files

