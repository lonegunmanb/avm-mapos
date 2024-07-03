# Customer Managed Keys

You can check the [official documentation](https://azure.github.io/Azure-Verified-Modules/specs/shared/interfaces/#customer-managed-keys) for more information.

In AVM Terraform module the customer managed keys interface looks like:

```hcl
variable "customer_managed_key" {
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
```

Then you could run `mapotf`:

```Shell
mapotf transform --tf-dir . --mptf-dir git::https://github.com/lonegunmanb/avm-mapos.git//customer_managed_keys
```

Then you would see the following Terraform config:

`variables.tf`

```hcl
variable "customer_managed_key" {

  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default = null
}
```