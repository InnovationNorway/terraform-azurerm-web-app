output "id" {
  value       = azurerm_app_service.main.id
  description = "The ID of the web app."
}

output "name" {
  value       = azurerm_app_service.main.name
  description = "The name of the web app."
}

output "hostname" {
  value       = azurerm_app_service.main.default_site_hostname
  description = "The default hostname of the web app."
}

output "identity" {
  value = {
    principal_id = azurerm_app_service.main.identity[0].principal_id
    ids          = azurerm_app_service.main.identity[0].identity_ids
  }
  description = "Managed service identity properties for the web app."
}

output "plan" {
  value = {
    id = azurerm_app_service.main.app_service_plan_id
  }
  description = "App Service plan properties for the web app."
}

output "outbound_ips" {
  value       = split(",", azurerm_app_service.main.outbound_ip_addresses)
  description = "A list of outbound IP addresses for the web app."
}

output "possible_outbound_ips" {
  value       = split(",", azurerm_app_service.main.possible_outbound_ip_addresses)
  description = "A list of possible outbound IP addresses for the web app. Superset of `outbound_ips`."
}
