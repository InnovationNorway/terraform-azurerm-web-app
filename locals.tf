locals {
    app_service_plan_name = "${var.web_app_name}-${var.environment}-plan"
    web_app_name = "${var.web_app_name}-${var.environment}-web"
    autoscale_settings_name = "${var.web_app_name}-${var.environment}-autoscale"
}
