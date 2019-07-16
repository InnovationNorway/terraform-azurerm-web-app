variable "resource_group_name" {
  description = "The resource group where the resources should be created."
}

variable "location" {
  default     = ""
  description = "The azure datacenter location where the resources should be created."
}

variable "name" {
  description = "The name for the web app."
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

variable "ip_restrictions" {
  type        = list(string)
  default     = []
  description = "A list of IP addresses in CIDR format specifying Access Restrictions."
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

variable "secure_app_settings" {
  type        = map(string)
  default     = {}
  description = "Set sensitive app settings. Uses Key Vault references as values for app settings."
}

variable "scaling" {
  type = any
  # type = object({
  #   enable    = bool
  #   min_count = number
  #   max_count = number 
  #   rules     = list 
  # })
  default     = {}
  description = "A `scaling` object."
}

variable "key_vault_id" {
  type        = string
  default     = ""
  description = "The ID of an existing Key Vault. Required if `secure_app_settings` is set."
}

variable "custom_hostnames" {
  type        = list(string)
  default     = []
  description = "List of custom hostnames to use for the web app."
}

variable "plan" {
  type        = map(string)
  default     = {}
  description = "A map of app service plan properties."
}

variable "runtime" {
  type = object({
    name    = string
    version = string
  })
  default = {
    name    = "node"
    version = "lts"
  }
  description = "A map of web app runtime properties."
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)

  default = {
  }
}

locals {
  is_shared_plan = contains(["F1", "FREE", "D1", "SHARED"], upper(local.plan.sku_size))

  always_on = local.is_shared_plan ? false : true

  use_32_bit_worker_process = (
    local.is_shared_plan && local.os_type == "windows" ? true : false
  )

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

  default_plan_name = format("%s-plan", var.name)

  plan = merge({
    id       = ""
    name     = ""
    sku_size = "F1"
    os_type  = "linux"
  }, var.plan)

  plan_id = coalesce(local.plan.id, azurerm_app_service_plan.main[0].id)

  runtime_name = lower(var.runtime.name)

  os_type = local.runtime_name == "aspnet" ? "windows" : lower(local.plan.os_type)

  # FIXME: create a data source to get supported runtimes
  runtime_versions = {
    windows = {
      aspnet = ["3.5", "4.7"]
      node   = ["10.6", "10.0", "8.11", "8.10", "8.9", "8.5", "8.4", "8.1", "7.10", "6.12", "6.9", "6.5", "4.8", "0.12", "0.10", "0.8", "0.6"]
      php    = ["7.3", "7.2", "7.1", "7.0", "5.6"]
      python = ["2.7", "3.6"]
      java   = ["11", "1.8", "1.7"]
    }
    linux = {
      ruby       = ["2.6.2", "2.5.5", "2.4.5", "2.3.8"]
      node       = ["lts", "10.14", "10.12", "10.10", "10.1", "9.4", "8.12", "8.11", "8.9", "8.8", "8.2", "8.1", "8.0", "6.11", "6.10", "6.9", "6.6", "6.2", "4.8", "4.5", "4.4"]
      php        = ["7.3", "7.2", "7.0", "5.6"]
      dotnetcore = ["2.2", "2.1", "2.0", "1.1", "1.0"]
      java       = ["11-java11", "8-jre"]
      tomcat     = ["9.0-java11", "8.5-java11", "9.0-jre8", "8.5-jre8"]
      wildfly    = ["14-jre8"]
      python     = ["3.7", "3.6", "2.7"]
    }
  }
  supported_runtimes = {
    for os_type, runtime in local.runtime_versions :
    os_type => {
      for name, versions in runtime :
      name => {
        for version in versions :
        version => true
      }
    }
  }
  check_supported_runtimes = (
    local.supported_runtimes[local.os_type][local.runtime_name][var.runtime.version]
  )

  dotnet_clr_versions = {
    "3.5" = "v2.0"
    "4.7" = "v4.0"
  }

  node_default_version = (
    local.os_type == "windows" ?
    {
      WEBSITE_NODE_DEFAULT_VERSION = (
        local.runtime_name == "node" ? var.runtime.version : "8.11.1"
      )
    } : {}
  )

  # FIXME: create a data source to get available SKUs
  skus = {
    "Free"             = ["F1", "Free"]
    "Shared"           = ["D1", "Shared"]
    "Basic"            = ["B1", "B2", "B3"]
    "Standard"         = ["S1", "S2", "S3"]
    "Premium"          = ["P1", "P2", "P3"]
    "PremiumV2"        = ["P1v2", "P2v2", "P3v2"]
    "PremiumContainer" = ["PC2", "PC3", "PC4"]
    "ElasticPremium"   = ["EP1", "EP2", "EP3"]
  }

  flattened_skus = flatten([
    for tier, sizes in local.skus : [
      for size in sizes : {
        tier = tier
        size = size
      }
    ]
  ])

  sku_tiers = { for sku in local.flattened_skus : sku.size => sku.tier }

  scaling = merge({
    min_count = 1
    max_count = null
    rules     = []
  }, var.scaling)

  client_affinity_enabled = local.scaling.max_count != null ? true : false
}
