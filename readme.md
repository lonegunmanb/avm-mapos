Some [`mapotf`](https://github.com/Azure/mapotf) configs that help you applied [Avm Interfaces](https://azure.github.io/Azure-Verified-Modules/specs/shared/interfaces/) on your Terraform modules.

* [Customer Managed Keys](customer_managed_keys/readme.md)
* [Diagnostic Settings](customer_managed_keys/readme.md)
* [Managed Identities](managed_identities/readme.md)
* [Private Endpoints](private_endpoints/readme.md)
* [Resource Locks](resource_locks/readme.md)
* [Role Assignments](role_assignments/readme.md)

You can check them one by one, or all together by:

```Shell
newres -r azurerm_storage_account -u -dir .
mapotf transform --tf-dir . --mptf-dir git::https://github.com/lonegunmanb/avm-mapos.git//customer_managed_keys \
 --mptf-var target_resource_address=azurerm_storage_account.this \
 --mptf-dir git::https://github.com/lonegunmanb/avm-mapos.git//diagnostic_settings \
 --mptf-var support_user_assigned=true --mptf-var support_system_assigned=true \
 --mptf-dir git::https://github.com/lonegunmanb/avm-mapos.git//managed_identities \
 --mptf-var multiple_underlying_services=true \
 --mptf-dir git::https://github.com/lonegunmanb/avm-mapos.git//private_endpoints \
 --mptf-dir git::https://github.com/lonegunmanb/avm-mapos.git//resource_locks \
 --mptf-dir git::https://github.com/lonegunmanb/avm-mapos.git//role_assignments
```