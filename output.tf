output "identity_principal_id" {
  description = "The MSI identity principal id set on the function app."
  value       = azurerm_app_service.main.identity[0].principal_id
}

output "identity_tenant_id" {
  description = "The MSI identity tenant id set on the function app."
  value       = azurerm_app_service.main.identity[0].tenant_id
}

output "webapp_name" {
  description = "The name of the created web app."
  value       = azurerm_app_service.main.name
}

output "plan_id" {
  description = "The id of the app service plan."
  value       = local.plan_id
}

output "hostname" {
  description = "The Hostname associated with the Web App - such as mysite.azurewebsites.net"
  value       = azurerm_app_service.main.default_site_hostname
}

output "outbound_ips" {
  value       = split(",", azurerm_app_service.main.outbound_ip_addresses)
  description = "A list of outbound IP addresses for the web app."
}

output "possible_outbound_ips" {
  value       = split(",", azurerm_app_service.main.possible_outbound_ip_addresses)
  description = "A list of possible outbound IP addresses for the web app. Superset of outbound_ips."
}
