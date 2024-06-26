transform "new_block" "diagnostic_settings_variable" {
  new_block_type = "variable"
  filename = "variables.tf"
  labels = ["diagnostic_settings"]
  asraw {
    type = map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    }))
    default  = {}
    nullable = false

    validation {
      condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
      error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
    }
    validation {
      condition = alltrue(
        [
          for _, v in var.diagnostic_settings :
          v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
        ]
      )
      error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
    }
    description = <<DESCRIPTION
  A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
  - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
  - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
  DESCRIPTION
  }
}

transform "new_block" "azurerm_monitor_diagnostic_setting_resource" {
  filename       = "main.tf"
  new_block_type = "resource"
  labels         = ["azurerm_monitor_diagnostic_setting", "this"]
  asraw {
    for_each                       = var.diagnostic_settings
    storage_account_id             = each.value.storage_account_resource_id
    eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
    eventhub_name                  = each.value.event_hub_name
    partner_solution_id            = each.value.marketplace_partner_resource_id
    log_analytics_workspace_id     = each.value.workspace_resource_id
    log_analytics_destination_type = each.value.log_analytics_destination_type

    dynamic "enabled_log" {
      for_each = each.value.log_categories
      content {
        category = enabled_log.value
      }
    }

    dynamic "enabled_log" {
      for_each = each.value.log_groups
      content {
        category_group = enabled_log.value
      }
    }

    dynamic "metric" {
      for_each = each.value.metric_categories
      content {
        category = metric.value
      }
    }
  }
  asstring {
    name                           = "each.value.name != null ? each.value.name : ${coalesce(var.monitor_diagnostic_setting_default_name, "\"diag-$${${var.target_resource_address}.name}\"")}"
    target_resource_id             = "${var.target_resource_address}.id"
  }
}

variable "target_resource_address" {
  type    = string
  validation {
    condition = startswith(var.target_resource_address, "azurerm_")
    error_message = "The target resource address must be an Azure resource type."
  }
}

variable "monitor_diagnostic_setting_default_name" {
  type    = string
  default = null
}