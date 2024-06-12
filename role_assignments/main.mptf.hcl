transform "new_block" "role_assignments_variable" {
  new_block_type = "variable"
  filename       = "variables.tf"
  labels = ["role_assignments"]
  asraw {
    type = map(object({
      role_definition_id_or_name = string
      principal_id               = string
      description = optional(string, null)
      skip_service_principal_aad_check = optional(bool, false)
      condition = optional(string, null)
      condition_version = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type = optional(string, null)
    }))
    default = {}
    nullable    = false
    description = <<DESCRIPTION
  A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
  }
}

transform "new_block" "role_assignments_local" {
  new_block_type = "locals"
  filename       = "role_assignments.tf"
  labels = []
  asraw {
    role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"
  }
}

variable "target_resource_address" {
  type    = string
  validation {
    condition = startswith(var.target_resource_address, "azurerm_")
    error_message = "The target resource address must be an Azure resource type."
  }
}

transform "new_block" "role_assignments_resource" {
  new_block_type = "resource"
  filename       = "role_assignments.tf"
  labels = ["azurerm_role_assignment", "this"]
  asraw {
    for_each                               = var.role_assignments
    role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
    role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
    principal_id                           = each.value.principal_id
    condition                              = each.value.condition
    condition_version                      = each.value.condition_version
    skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
    delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
    principal_type                         = each.value.principal_type
  }
  asstring {
    scope                                  = "${var.target_resource_address}.id"
  }
}