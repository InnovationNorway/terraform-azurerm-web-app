variable "resource_group_name" {
  description = "The resource group where the resources should be created."
}

variable "location" {
  default     = "westeurope"
  description = "The azure datacenter location where the resources should be created."
}

variable "name" {
  description = "The name for the web app."
}

variable "app_service_plan_id" {
  type        = string
  default     = ""
  description = "The ID of an existing app service plan to use for the web app."
}

variable "sku" {
  type        = string
  default     = "Basic_B1"
  description = "The SKU of an app service plan to create for the web app."
}

variable "min_tls_version" {
  description = "Minimum version of TLS the web app should support."
  default     = "1.2"
}

variable "restrict_ip" {
  default     = "0.0.0.0"
  description = "The ipv4 address you want to allow accessing the web app"
}

variable "restrict_subnet_mask" {
  default     = "0.0.0.0"
  description = "The subnet mask for the ipv4 address you want to allow accessing the web app, defaults to 0.0.0.0 (every ip allowed)"
}

variable "ftps_state" {
  description = "Which form for ftp the web app file system should support. If not strictly nesasery to use it, leave it disabled, and onlyftps if needed."
  default     = "Disabled"
}

variable "app_settings" {
  default = {
  }
  type        = map(string)
  description = "Application settings to insert on creating the function app. Following updates will be ignored, and has to be set manually. Updates done on application deploy or in portal will not affect terraform state file."
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)

  default = {
  }
}
