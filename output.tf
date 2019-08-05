output "identity_principal_id" {
  description = "The MSI identity principal id set on the function app."
  value       = "${azurerm_app_service.webapp.identity.0.principal_id}"
}

output "identity_tenant_id" {
  description = "The MSI identity tenant id set on the function app."
  value       = "${azurerm_app_service.webapp.identity.0.tenant_id}"
}

output "webapp_name" {
  description = "The name of the created web app."
  value = "${azurerm_app_service.webapp.name}"
}

output "webapp_serviceplan_name" {
  description = "The name of the created web app service plan."
  value = "${azurerm_app_service_plan.serviceplan.name}"
}

output "webapp_serviceplan_id" {
  description = "The id of the created web app service plan."
  value = "${azurerm_app_service_plan.serviceplan.id}"
}

output "hostname" {
  description = "The Hostname associated with the Web App - such as mysite.azurewebsites.net"
  value = "${azurerm_app_service.webapp.default_site_hostname}"
}

output "outbound_ip_addresses" {
  value = "${azurerm_app_service.webapp.outbound_ip_addresses}"
}
