# Private Endpoints

You can check the [official documentation](https://azure.github.io/Azure-Verified-Modules/specs/shared/interfaces/#private-endpoints) for more information.

In AVM Terraform module the private endpoints interface looks like:

```hcl
# In this example we only support one service, e.g. Key Vault.
# If your service has multiple private endpoint services, then expose the service name.

# This variable is used to determine if the private_dns_zone_group block should be included,
# or if it is to be managed externally, e.g. using Azure Policy.
# https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault/issues/32
# Alternatively you can use AzAPI, which does not have this issue.
variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  nullable    = false
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string # NOTE: `subresource_name` can be excluded if the resource does not support multiple sub resource types (e.g. storage account supports blob, queue, etc)
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
  A map of private endpoints to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
    - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
    - `principal_id` - The ID of the principal to assign the role to.
    - `description` - (Optional) The description of the role assignment.
    - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
    - `condition` - (Optional) The condition which will be used to scope the role assignment.
    - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
    - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
    - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
  - `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
    - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
    - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  - `tags` - (Optional) A mapping of tags to assign to the private endpoint.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `subresource_name` - The name of the sub resource for the private endpoint.
  - `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
  - `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
  - `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the Key Vault.
  - `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
    - `name` - The name of the IP configuration.
    - `private_ip_address` - The private IP address of the IP configuration.
  DESCRIPTION
}

# The PE resource when we are managing the private_dns_zone_group block:
resource "azurerm_private_endpoint" "this" {
  for_each                      = { for k, v in var.private_endpoints : k => v if var.private_endpoints_manage_dns_zone_group }
  name                          = each.value.name != null ? each.value.name : "pep-${var.name}"
  location                      = each.value.location != null ? each.value.location : var.location
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["MYSERVICE"] # map to each.value.subresource_name if there are multiple services.
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      subresource_name   = "MYSERVICE" # map to each.value.subresource_name if there are multiple services.
      member_name        = "MYSERVICE" # map to each.value.subresource_name if there are multiple services.
      private_ip_address = ip_configuration.value.private_ip_address
    }
  }
}

# The PE resource when we are managing **not** the private_dns_zone_group block:
resource "azurerm_private_endpoint" "this_unmanaged_dns_zone_groups" {
  for_each = { for k, v in var.private_endpoints : k => v if ! var.private_endpoints_manage_dns_zone_group }

  # ... repeat configuration above
  # **omitting the private_dns_zone_group block**
  # then add the following lifecycle block to ignore changes to the private_dns_zone_group block

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
}

# Private endpoint application security group associations.
# We merge the nested maps from private endpoints and application security group associations into a single map.
locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each                      = local.private_endpoint_application_security_group_associations
  private_endpoint_id           = azurerm_private_endpoint.this[each.value.pe_key].id
  application_security_group_id = each.value.asg_resource_id
}

# You need an additional resource when not managing private_dns_zone_group with this module:

# In your output you need to select the correct resource based on the value of var.private_endpoints_manage_dns_zone_group:
output "private_endpoints" {
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
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
mapotf transform --mptf-var target_resource_address=azurerm_storage_account.this  --mptf-var multiple_underlying_services=true --tf-dir . --mptf-dir git::https://github.com/lonegunmanb/avm-mapos.git//private_endpoints
```

Since `azurerm_storage_account` does have multiple underlying services, like blob container, queue and table, we set `--mptf-var multiple_underlying_services=true` here.

Then you would see the following Terraform config:

`main.privateendpoint.tf`

```hcl
locals {
  private_endpoint_application_security_group_associations = {
    for assoc in flatten([
      for pe_k, pe_v in var.private_endpoints : [
        for asg_k, asg_v in pe_v.application_security_group_associations : {
          asg_key         = asg_k
          pe_key          = pe_k
          asg_resource_id = asg_v
        }
      ]
    ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc
  }
}

resource "azurerm_private_endpoint" "this" {

  for_each = { for k, v in var.private_endpoints : k => v if var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : azurerm_storage_account.this.location
  name                          = each.value.name != null ? each.value.name : lower("pep-${each.value.subresource_name}")
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : azurerm_storage_account.this.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {

    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${azurerm_storage_account.this.name}"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = each.value.subresource_name
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations
    content {

      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = each.value.subresource_name
      subresource_name   = each.value.subresource_name
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []
    content {

      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }
}

resource "azurerm_private_endpoint" "this_unmanaged_dns_zone_groups" {

  for_each = { for k, v in var.private_endpoints : k => v if !var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : azurerm_storage_account.this.location
  name                          = each.value.name != null ? each.value.name : lower("pep-${each.value.subresource_name}")
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : azurerm_storage_account.this.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {

    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${azurerm_storage_account.this.name}"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = each.value.subresource_name
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations
    content {

      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = each.value.subresource_name
      subresource_name   = each.value.subresource_name
    }
  }

  lifecycle {

    ignore_changes = [private_dns_zone_group]
  }
}
```

`variables.tf`

```hcl
variable "private_endpoints_manage_dns_zone_group" {

  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}

variable "private_endpoints" {

  type = map(object({
    name = optional(string, null)
    # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#role-assignments
    role_assignments = optional(map(object({})), {})
    # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#resource-locks
    lock = optional(object({}), {})
    # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#tags
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of private endpoints to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
  - `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
  - `tags` - (Optional) A mapping of tags to assign to the private endpoint.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
  - `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
  - `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the Key Vault.
  - `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
    - `name` - The name of the IP configuration.
    - `private_ip_address` - The private IP address of the IP configuration.
  DESCRIPTION
  nullable    = false
}
```
