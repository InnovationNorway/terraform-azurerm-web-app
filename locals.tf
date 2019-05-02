locals {
  app_service_plan_name   = "${var.name}-plan"
  name                    = "${var.name}"
  autoscale_settings_name = "${var.name}-autoscale"
}
