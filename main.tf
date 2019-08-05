data "azurerm_client_config" "main" {}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_app_service_plan" "main" {
  count               = local.plan.id != "" ? 1 : 0
  name                = split("/", local.plan.id)[8]
  resource_group_name = split("/", local.plan.id)[4]
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_app_service" "main" {
  name                = var.name
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  app_service_plan_id = coalesce(local.plan.id, azurerm_app_service_plan.main[0].id)

  https_only              = var.https_only
  client_affinity_enabled = local.client_affinity_enabled

  site_config {
    always_on                 = local.always_on
    http2_enabled             = var.http2_enabled
    ip_restriction            = local.ip_restrictions
    ftps_state                = var.ftps_state
    min_tls_version           = var.min_tls_version
    use_32_bit_worker_process = local.use_32_bit_worker_process

    dotnet_framework_version = local.dotnet_framework_version
    php_version              = local.php_version
    python_version           = local.python_version

    linux_fx_version = local.linux_fx_version
  }

  app_settings = local.app_settings

  identity {
    type = (local.identity.enabled ?
      (local.identity.ids != null ? "SystemAssigned, UserAssigned" : "SystemAssigned") :
      "None"
    )
    identity_ids = local.identity.ids
  }

  dynamic "auth_settings" {
    for_each = local.auth.enabled ? [local.auth] : []

    content {
      enabled             = auth_settings.value.enabled
      issuer              = format("https://sts.windows.net/%s/", data.azurerm_client_config.main.tenant_id)
      token_store_enabled = local.auth.token_store_enabled
      additional_login_params = {
        response_type = "code id_token"
        resource      = local.auth.active_directory.client_id
      }
      default_provider = "AzureActiveDirectory"

      dynamic "active_directory" {
        for_each = [auth_settings.value.active_directory]

        content {
          client_id     = active_directory.value.client_id
          client_secret = active_directory.value.client_secret
          allowed_audiences = formatlist("https://%s", concat(
          [format("%s.azurewebsites.net", var.name)], var.custom_hostnames))
        }
      }
    }
  }

  dynamic "storage_account" {
    for_each = local.storage_mounts
    iterator = s

     content {
      name         = s.value.name
      type         = s.value.share_name != "" ? "AzureFiles" : "AzureBlob"
      account_name = s.value.account_name
      share_name   = s.value.share_name != "" ? s.value.share_name : s.value.container_name
      access_key   = s.value.access_key
      mount_path   = s.value.mount_path
    }
  }

  tags = var.tags

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

resource "azurerm_monitor_autoscale_setting" "main" {
  count               = local.scaling.enabled ? 1 : 0
  name                = format("%s-autoscale", var.name)
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  target_resource_id  = azurerm_app_service.main.app_service_plan_id

  profile {
    name = "default"

    capacity {
      default = local.scaling.min_count
      minimum = local.scaling.min_count
      maximum = local.scaling.max_count
    }

    dynamic "rule" {
      for_each = { for k, v in local.scaling_rules : k => v }

      content {
        metric_trigger {
          metric_name        = local.metric_triggers[rule.key].metric_name
          metric_resource_id = local.metric_triggers[rule.key].metric_resource_id
          time_grain         = local.metric_triggers[rule.key].time_grain
          statistic          = local.metric_triggers[rule.key].statistic
          time_window        = local.metric_triggers[rule.key].time_window
          time_aggregation   = local.metric_triggers[rule.key].time_aggregation
          operator           = local.metric_triggers[rule.key].operator
          threshold          = local.metric_triggers[rule.key].threshold
        }

        scale_action {
          direction = local.scale_actions[rule.key].direction
          type      = local.scale_actions[rule.key].type
          value     = local.scale_actions[rule.key].value
          cooldown  = local.scale_actions[rule.key].cooldown
        }
      }
    }
  }
}
