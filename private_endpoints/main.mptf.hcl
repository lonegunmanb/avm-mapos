transform "new_block" "private_endpoints_manage_dns_zone_group_variable" {
  new_block_type = "variable"
  filename       = "variables.tf"
  labels = ["private_endpoints_manage_dns_zone_group"]
  asraw {
    type        = bool
    default     = true
    nullable    = false
    description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  }
}

variable "multiple_underlying_services" {
  type    = bool
  default = false
}

transform "new_block" "private_endpoints_variable" {
  for_each = var.multiple_underlying_services ?  [] : ["private_endpoints_variable"]

  new_block_type = "variable"
  filename       = "variables.tf"
  labels = ["private_endpoints"]
  asraw {
    type = map(object({
      name = optional(string, null)
      # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#role-assignments
      role_assignments = optional(map(object({})), {})
      # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#resource-locks
      lock = optional(object({}), {})
      # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#tags
      tags = optional(map(string), null)
      subnet_resource_id = string
      private_dns_zone_group_name = optional(string, "default")
      private_dns_zone_resource_ids = optional(set(string), [])
      application_security_group_associations = optional(map(string), {})
      private_service_connection_name = optional(string, null)
      network_interface_name = optional(string, null)
      location = optional(string, null)
      resource_group_name = optional(string, null)
      ip_configurations = optional(map(object({
        name               = string
        private_ip_address = string
      })), {})
    }))
    default = {}
    nullable    = false
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
  }
}

transform "new_block" "private_endpoints_multiple_underlying_services_variable" {
  for_each = var.multiple_underlying_services ? ["private_endpoints_multiple_underlying_services_variable"] : []

  new_block_type = "variable"
  filename       = "variables.tf"
  labels = ["private_endpoints"]
  asraw {
    type = map(object({
      name = optional(string, null)
      # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#role-assignments
      role_assignments = optional(map(object({})), {})
      # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#resource-locks
      lock = optional(object({}), {})
      # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#tags
      tags = optional(map(string), null)
      subnet_resource_id = string
      subresource_name   = string
      private_dns_zone_group_name = optional(string, "default")
      private_dns_zone_resource_ids = optional(set(string), [])
      application_security_group_associations = optional(map(string), {})
      private_service_connection_name = optional(string, null)
      network_interface_name = optional(string, null)
      location = optional(string, null)
      resource_group_name = optional(string, null)
      ip_configurations = optional(map(object({
        name               = string
        private_ip_address = string
      })), {})
    }))
    default = {}
    nullable    = false
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
  }
}

transform "new_block" "private_endpoint_local" {
  new_block_type = "locals"
  filename       = "main.privateendpoint.tf"
  labels = []
  asraw {
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
}

variable "service_name" {
  type    = string
  default = ""
}

variable "target_resource_address" {
  type    = string
  validation {
    condition = startswith(var.target_resource_address, "azurerm_")
    error_message = "The target resource address must be an Azure resource type."
  }
}

locals {
  private_endpoint_name = var.multiple_underlying_services ? "each.value.name != null ? each.value.name : lower(\"pep-$${each.value.subresource_name}\")" : "each.value.name != null ? each.value.name : lower(\"pep-$${${var.service_name}.name}\")"
}

transform "new_block" "private_endpoint" {
  new_block_type = "resource"
  filename       = "main.privateendpoint.tf"
  labels = ["azurerm_private_endpoint", "this"]
  asraw {
    for_each                      = { for k, v in var.private_endpoints : k => v if var.private_endpoints_manage_dns_zone_group }
    subnet_id                     = each.value.subnet_resource_id
    custom_network_interface_name = each.value.network_interface_name
    tags                          = each.value.tags

    dynamic "private_dns_zone_group" {
      for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

      content {
        name                 = each.value.private_dns_zone_group_name
        private_dns_zone_ids = each.value.private_dns_zone_resource_ids
      }
    }
  }
  asstring {
    name                          = local.private_endpoint_name
    location                      = "each.value.location != null ? each.value.location : ${var.target_resource_address}.location"
    resource_group_name           = "each.value.resource_group_name != null ? each.value.resource_group_name : ${var.target_resource_address}.resource_group_name"
    private_service_connection {
      name                           = "each.value.private_service_connection_name != null ? each.value.private_service_connection_name : \"pse-$${${var.target_resource_address}.name}\""
      private_connection_resource_id = "${var.target_resource_address}.id"
      is_manual_connection           = "false"
      subresource_names = local.subresource_name_list
    }
    dynamic "ip_configuration" {
      for_each = "each.value.ip_configurations"

      content {
        name               = "ip_configuration.value.name"
        subresource_name   = local.subresource_name
        member_name        = local.subresource_name
        private_ip_address = "ip_configuration.value.private_ip_address"
      }
    }
  }
  precondition {
    condition = var.service_name != "" || var.multiple_underlying_services
    error_message = "The `var.service_name` variable must be set when `var.multiple_underlying_services` is false."
  }
}

locals {
  subresource_name = var.multiple_underlying_services ? "each.value.subresource_name" : "\"${var.service_name}\""
  subresource_name_list = var.multiple_underlying_services ? "each.value.subresource_name" : "[\"${var.service_name}\"]"
}

transform "new_block" "private_endpoint_this_unmanaged_dns_zone_groups" {
  new_block_type = "resource"
  filename       = "main.privateendpoint.tf"
  labels = ["azurerm_private_endpoint", "this_unmanaged_dns_zone_groups"]
  asraw {
    for_each                      = { for k, v in var.private_endpoints : k => v if !var.private_endpoints_manage_dns_zone_group }
    subnet_id                     = each.value.subnet_resource_id
    custom_network_interface_name = each.value.network_interface_name
    tags                          = each.value.tags

    lifecycle {
      ignore_changes = [private_dns_zone_group]
    }
  }
  asstring {
    name                          = local.private_endpoint_name
    location                      = "each.value.location != null ? each.value.location : ${var.target_resource_address}.location"
    resource_group_name           = "each.value.resource_group_name != null ? each.value.resource_group_name : ${var.target_resource_address}.resource_group_name"
    private_service_connection {
      name                           = "each.value.private_service_connection_name != null ? each.value.private_service_connection_name : \"pse-$${${var.target_resource_address}.name}\""
      private_connection_resource_id = "${var.target_resource_address}.id"
      is_manual_connection           = "false"
      subresource_names = local.subresource_name_list
    }
    dynamic "ip_configuration" {
      for_each = "each.value.ip_configurations"

      content {
        name               = "ip_configuration.value.name"
        subresource_name   = local.subresource_name
        member_name        = local.subresource_name
        private_ip_address = "ip_configuration.value.private_ip_address"
      }
    }
  }
  precondition {
    condition = var.service_name != "" || var.multiple_underlying_services
    error_message = "The `var.service_name` variable must be set when `var.multiple_underlying_services` is false."
  }
}