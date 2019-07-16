data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_app_service_plan" "main" {
  count               = local.plan.id == "" ? 1 : 0
  name                = coalesce(local.plan.name, local.default_plan_name)
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  kind                = local.os_type
  reserved            = local.os_type == "linux" ? true : null

  sku {
    tier = local.sku_tiers[local.plan.sku_size]
    size = local.plan.sku_size
  }

  tags = var.tags
}

resource "azurerm_app_service" "main" {
  name                    = var.name
  location                = local.location
  resource_group_name     = data.azurerm_resource_group.main.name
  app_service_plan_id     = local.plan_id
  https_only              = true
  client_affinity_enabled = local.client_affinity_enabled

  tags = var.tags

  site_config {
    always_on       = local.always_on
    http2_enabled   = true
    min_tls_version = var.min_tls_version
    ip_restriction  = local.ip_restrictions
    ftps_state      = var.ftps_state

    use_32_bit_worker_process = local.use_32_bit_worker_process

    dotnet_framework_version = (
      var.runtime.name == "aspnet" ?
      local.dotnet_clr_versions[var.runtime.version] : null
    )

    php_version = (
      local.os_type == "windows" && var.runtime.name == "php" ?
      var.runtime.version : null
    )

    python_version = (
      local.os_type == "windows" && var.runtime.name == "python" ?
      var.runtime.version : null
    )

    linux_fx_version = (
      local.os_type == "linux" ?
      format("%s|%s", upper(var.runtime.name), var.runtime.version) : null
    )
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = merge(
    var.app_settings,
    local.secure_app_settings,
    local.node_default_version
  )

  depends_on = [azurerm_key_vault_secret.main]
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
