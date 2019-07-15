locals {
  app_service_plan_id = coalesce(var.app_service_plan_id, azurerm_app_service_plan.main[0].id)

  ip_restrictions = [
    for prefix in var.ip_restrictions : {
      ip_address  = split("/", prefix)[0]
      subnet_mask = cidrnetmask(prefix)
    }
  ]

  location = coalesce(var.location, data.azurerm_resource_group.main.location)

  key_vault_secrets = [
    for name, value in var.secure_app_settings : {
      name  = replace(name, "/[^a-zA-Z0-9-]/", "-")
      value = value
    }
  ]

  secure_app_settings = {
    for secret in azurerm_key_vault_secret.main :
    replace(secret.name, "-", "_") => format("@Microsoft.KeyVault(SecretUri=%s)", secret.id)
  }

  depends_on = [azurerm_key_vault_secret.main]
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_app_service_plan" "main" {
  count               = var.app_service_plan_id == "" ? 1 : 0
  name                = format("%s-plan", var.name)
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name

  sku {
    tier = split("_", var.sku)[0]
    size = split("_", var.sku)[1]
  }

  tags = var.tags
}

resource "azurerm_app_service" "main" {
  name                    = var.name
  location                = local.location
  resource_group_name     = data.azurerm_resource_group.main.name
  app_service_plan_id     = local.app_service_plan_id
  https_only              = true
  client_affinity_enabled = false

  tags = var.tags

  site_config {
    always_on       = true
    http2_enabled   = true
    min_tls_version = var.min_tls_version
    ip_restriction  = local.ip_restrictions
    ftps_state      = var.ftps_state
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = merge(var.app_settings, local.secure_app_settings)
}

resource "azurerm_app_service_custom_hostname_binding" "main" {
  count               = length(var.custom_hostnames)
  hostname            = var.custom_hostnames[count.index]
  app_service_name    = azurerm_app_service.main.name
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_key_vault_access_policy" "main" {
  count              = length(var.secure_app_settings) > 0 ? 1 : 0
  key_vault_id       = var.key_vault_id
  tenant_id          = azurerm_app_service.main.identity[0].tenant_id
  object_id          = azurerm_app_service.main.identity[0].principal_id
  secret_permissions = ["get"]
}

resource "azurerm_key_vault_secret" "main" {
  count        = length(local.key_vault_secrets)
  key_vault_id = var.key_vault_id
  name         = local.key_vault_secrets[count.index].name
  value        = local.key_vault_secrets[count.index].value
}
