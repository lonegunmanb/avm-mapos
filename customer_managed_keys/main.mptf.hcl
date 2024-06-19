transform "new_block" "customer_managed_key_variable" {
  new_block_type = "variable"
  filename = "variables.tf"
  labels = ["customer_managed_key"]
  asraw {
    type = object({
      key_vault_resource_id  = string
      key_name               = string
      key_version            = optional(string, null)
      user_assigned_identity = optional(object({
        resource_id = string
      }), null)
    })
    default = null
  }
}