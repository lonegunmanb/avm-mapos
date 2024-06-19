transform "new_block" "managed_identities_variable" {
  new_block_type = "variable"
  filename       = "variables.tf"
  labels = ["managed_identities"]
  asraw {
    type = object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
    })
    default     = {}
    nullable    = false
    description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  }
}

transform "new_block" "managed_identities_local" {
  new_block_type = "locals"
  filename       = "main.tf"
  labels = []
  asraw {
    managed_identities = {
      system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
        this = {
          type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
          user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
        }
      } : {}
      system_assigned = var.managed_identities.system_assigned ? {
        this = {
          type = "SystemAssigned"
        }
      } : {}
      user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
        this = {
          type                       = "UserAssigned"
          user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
        }
      } : {}
    }
  }
}

variable "target_resource_address" {
  type    = string
  validation {
    condition = startswith(var.target_resource_address, "azurerm_")
    error_message = "The target resource address must be an Azure resource type."
  }
}

variable support_system_assigned {
  type = bool
}

variable support_user_assigned {
  type = bool
}

transform "remove_nested_block" remove_identity {
  target_block_address = "resource.${var.target_resource_address}"
  paths = [
    "identity",
  ]
}

transform "update_in_place" "system_and_user_assigned" {
  for_each = var.support_system_assigned && var.support_user_assigned ? [var.target_resource_address] : []
  target_block_address = "resource.${each.value}"
  asraw {
    dynamic "identity" {
      for_each = local.managed_identities.system_assigned_user_assigned
      content {
        type         = identity.value.type
        identity_ids = identity.value.user_assigned_resource_ids
      }
    }
  }
  depends_on = [transform.remove_nested_block.remove_identity]
}

transform "update_in_place" "system_assigned_only" {
  for_each = var.support_system_assigned && !var.support_user_assigned ? [var.target_resource_address] : []
  target_block_address = "resource.${each.value}"
  asraw {
    dynamic "identity" {
      for_each = identity.managed_identities.system_assigned
      content {
        type = identity.value.type
      }
    }
  }
  depends_on = [transform.remove_nested_block.remove_identity]
}

transform "update_in_place" "user_assigned_only" {
  for_each = !var.support_system_assigned && var.support_user_assigned ? [var.target_resource_address] : []
  target_block_address = "resource.${each.value}"
  asraw {
    dynamic "identity" {
      for_each = local.managed_identities.user_assigned
      content {
        type         = identity.value.type
        identity_ids = identity.value.user_assigned_resource_ids
      }
    }
  }
  depends_on = [transform.remove_nested_block.remove_identity]
}