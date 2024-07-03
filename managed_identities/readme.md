# Managed Identities

You can check the [official documentation](https://azure.github.io/Azure-Verified-Modules/specs/shared/interfaces/#managed-identities) for more information.

In AVM Terraform module the managed identities interface looks like:

```hcl
variable "managed_identities" {
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

# Helper locals to make the dynamic block more readable
# There are three attributes here to cater for resources that
# support both user and system MIs, only system MIs, and only user MIs
locals {
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

## Resources supporting both SystemAssigned and UserAssigned
dynamic "identity" {
  for_each = local.managed_identities.system_assigned_user_assigned
  content {
    type         = identity.value.type
    identity_ids = identity.value.user_assigned_resource_ids
  }
}

## Resources that only support SystemAssigned
dynamic "identity" {
  for_each = identity.managed_identities.system_assigned
  content {
    type = identity.value.type
  }
}

## Resources that only support UserAssigned
dynamic "identity" {
  for_each = local.managed_identities.user_assigned
  content {
    type         = identity.value.type
    identity_ids = identity.value.user_assigned_resource_ids
  }
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
  
  dynamic "identity" {
    for_each = var.storage_account.identity == null ? [] : [var.storage_account.identity]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
}
```

Then you could run `mapotf`:

```Shell
mapotf transform --mptf-var target_resource_address=azurerm_storage_account.this  --mptf-var support_user_assigned=true --mptf-var support_system_assigned=true --tf-dir . --mptf-dir git::https://github.com/lonegunmanb/avm-mapos.git//managed_identities
```

Since `azurerm_storage_account` do support both `SystemAssigned` and `UserAssigned`, we set both `var.support_user_assigned` and `var.support_system_assigned` to `true.

Then you would see the following Terraform config:

`main.tf`

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
  
  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned
    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
}

locals {
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
```

`variables.tf`

```hcl
variable "managed_identities" {

  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}
```