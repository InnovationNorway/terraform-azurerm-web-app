locals {
  app_service_plan_name   = "${var.web_app_name}-plan"
  web_app_name            = "${var.web_app_name}-web"
  autoscale_settings_name = "${var.web_app_name}-autoscale"
}
