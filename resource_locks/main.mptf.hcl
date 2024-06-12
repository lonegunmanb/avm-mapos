transform "new_block" "locks_variable" {
  new_block_type = "variable"
  filename       = "variables.tf"
  labels = ["lock"]
  asraw {
    type = object({
      kind = string
      name = optional(string, null)
    })
    default     = null
    description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

    validation {
      condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
      error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
    }
  }
}

variable "target_resource_address" {
  type = string
  validation {
    condition = startswith(var.target_resource_address, "azurerm_")
    error_message = "The target resource address must be an Azure resource type."
  }
}

transform "new_block" "management_lock_resource" {
  new_block_type = "resource"
  filename       = "main.tf"
  labels = ["azurerm_management_lock", "this"]
  asraw {
    count = var.lock != null ? 1 : 0
    lock_level = var.lock.kind
    name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
    notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
  }
  asstring {
    scope = "${var.target_resource_address}.id"
  }
}