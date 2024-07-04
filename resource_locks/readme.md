# Resource Locks

You can check the [official documentation](https://azure.github.io/Azure-Verified-Modules/specs/shared/interfaces/#resource-locks) for more information.

In AVM Terraform module the resource locks interface looks like:

```hcl
variable "lock" {
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

# Example resource implementation
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_MY_RESOURCE.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}
```

Let's say you have a primary `azurerm_storage_account` resource. You can use [`newres`](https://github.com/lonegunmanb/newres) to create one:

```Shell
newres -r azurerm_storage_account -u -dir .
```

Then you would see the following Terraform config in your `main.tf` file:

```hcl
resource "azurerm_storage_account" "this" {
  account_replication_type          = var.storage_account.account_replication_type
  account_tier                      = var.storage_account.account_tier
  location                          = var.storage_account.location
  name                              = var.storage_account.name
  resource_group_name               = var.storage_account.resource_group_name
  access_tier                       = var.storage_account.access_tier
  account_kind                      = var.storage_account.account_kind
  allow_nested_items_to_be_public   = var.storage_account.allow_nested_items_to_be_public
  allowed_copy_scope                = var.storage_account.allowed_copy_scope
  cross_tenant_replication_enabled  = var.storage_account.cross_tenant_replication_enabled
  default_to_oauth_authentication   = var.storage_account.default_to_oauth_authentication
  dns_endpoint_type                 = var.storage_account.dns_endpoint_type
  edge_zone                         = var.storage_account.edge_zone
  enable_https_traffic_only         = var.storage_account.enable_https_traffic_only
  infrastructure_encryption_enabled = var.storage_account.infrastructure_encryption_enabled
  is_hns_enabled                    = var.storage_account.is_hns_enabled
  large_file_share_enabled          = var.storage_account.large_file_share_enabled
  local_user_enabled                = var.storage_account.local_user_enabled
  min_tls_version                   = var.storage_account.min_tls_version
  nfsv3_enabled                     = var.storage_account.nfsv3_enabled
  public_network_access_enabled     = var.storage_account.public_network_access_enabled
  queue_encryption_key_type         = var.storage_account.queue_encryption_key_type
  sftp_enabled                      = var.storage_account.sftp_enabled
  shared_access_key_enabled         = var.storage_account.shared_access_key_enabled
  table_encryption_key_type         = var.storage_account.table_encryption_key_type
  tags                              = var.storage_account.tags
}
```

Then you could run `mapotf`:

```Shell
mapotf transform --mptf-var target_resource_address=azurerm_storage_account.this --tf-dir . --mptf-dir git::https://github.com/lonegunmanb/avm-mapos.git//resource_locks
```

Then you would see the following Terraform config:

`main.tf`

```hcl
resource "azurerm_management_lock" "this" {

  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_storage_account.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}
```

`variables.tf`

```hcl
variable "lock" {

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
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
  }
}
```
