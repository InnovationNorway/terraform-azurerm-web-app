locals {
  app_service_plan_id = coalesce(var.app_service_plan_id, azurerm_app_service_plan.main[0].id)

  ip_restrictions = [
    for prefix in var.ip_restrictions : {
      ip_address  = split("/", prefix)[0]
      subnet_mask = cidrnetmask(prefix)
    }
  ]
}

resource "azurerm_app_service_plan" "main" {
  count               = var.app_service_plan_id == "" ? 1 : 0
  name                = format("%s-plan", var.name)
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    tier = split("_", var.sku)[0]
    size = split("_", var.sku)[1]
  }

  tags = var.tags
}

resource "azurerm_app_service" "main" {
  name                    = local.name
  location                = var.location
  resource_group_name     = var.resource_group_name
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

  app_settings = var.app_settings

  lifecycle {
    ignore_changes = [app_settings]
  }
}
