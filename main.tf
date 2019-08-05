resource "azurerm_app_service_plan" "serviceplan" {
  name                = "${local.app_service_plan_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  sku {
    tier = "${var.sku_tier}"
    size = "${var.sku_size}"
  }

  tags = "${merge(var.tags, map("environment", var.environment), map("release", var.release))}"
}

resource "azurerm_app_service" "webapp" {
  name                    = "${local.web_app_name}"
  location                = "${var.location}"
  resource_group_name     = "${var.resource_group_name}"
  app_service_plan_id     = "${azurerm_app_service_plan.serviceplan.id}"
  https_only              = true
  client_affinity_enabled = false

  tags = "${merge(var.tags, map("environment", var.environment), map("release", var.release))}"

  site_config {
    always_on       = true
    http2_enabled   = true
    min_tls_version = "${var.min_tls_version}"

    ip_restriction {
      ip_address  = "${var.restrict_ip}"
      subnet_mask = "${var.restrict_subnet_mask}"
    }

    ftps_state = "${var.ftps_state}"
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = "${var.app_settings}"

  lifecycle {
    ignore_changes = ["app_settings", "identity"]
  }
}

resource "azurerm_monitor_autoscale_setting" "app_service_auto_scale" {
  name                = "${local.autoscale_settings_name}"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  target_resource_id  = "${azurerm_app_service_plan.serviceplan.id}"

  profile {
    name = "Scale on CPU usage"

    capacity {
      default = "${var.default_autoscale_instances}"
      minimum = "${var.default_autoscale_instances}"
      maximum = "${azurerm_app_service_plan.serviceplan.maximum_number_of_workers}"
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = "${azurerm_app_service_plan.serviceplan.id}"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = "${azurerm_app_service_plan.serviceplan.id}"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    # operation = "Scale"

    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
    }
  }
}
