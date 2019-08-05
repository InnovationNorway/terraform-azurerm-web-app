variable "name" {
  type        = string
  description = "The name of the web app."
}

variable "resource_group_name" {
  type        = string
  description = "The name of an existing resource group."
}

variable "location" {
  type        = string
  default     = ""
  description = "The location where the web app should be created."
}

variable "https_only" {
  type        = bool
  default     = false
  description = "Redirect all traffic made to the web app using HTTP to HTTPS."
}

variable "http2_enabled" {
  type        = bool
  default     = true
  description = "Whether clients are allowed to connect over HTTP 2.0."
}

variable "min_tls_version" {
  type        = string
  default     = "1.2"
  description = "The minimum supported TLS version."
}

variable "ftps_state" {
  type        = string
  default     = "Disabled"
  description = "Set the FTPS state value the web app. The options are: `AllAllowed`, `Disabled` and `FtpsOnly`."
}

variable "app_settings" {
  type        = map(string)
  default     = {}
  description = "Map of App Settings."
}

variable "secure_app_settings" {
  type        = map(string)
  default     = {}
  description = "Map of sensitive app settings. Uses Key Vault references as values for app settings."
}

variable "key_vault_id" {
  type        = string
  default     = ""
  description = "The ID of an existing Key Vault. Required if `secure_app_settings` is set."
}

variable "ip_restrictions" {
  type        = list(string)
  default     = []
  description = "A list of IP addresses in CIDR format specifying Access Restrictions."
}

variable "custom_hostnames" {
  type        = list(string)
  default     = []
  description = "List of custom hostnames to use for the web app."
}

variable "plan" {
  type        = any
  default     = {}
  description = "App Service plan properties. This should be `plan` object."
}

variable "runtime" {
  type        = any
  default     = {}
  description = "Runtime settings for the web app. This should be `runtime` object."
}

variable "auth" {
  type        = any
  default     = {}
  description = "Auth settings for the web app. This should be `auth` object."
}

variable "identity" {
  type        = any
  default     = {}
  description = "Managed service identity properties. This should be `identity` object."
}

variable "scaling" {
  type        = any
  default     = {}
  description = "Autoscale settings for the web app. This should be `scaling` object."
}

variable "storage_mounts" {
  type        = any
  default     = []
  description = "List of storage mounts."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the web app."
}

locals {
  default_plan_name = format("%s-plan", var.name)

  plan = merge({
    id       = ""
    name     = ""
    sku_size = "F1"
    os_type  = "linux"
  }, var.plan)

  location = coalesce(var.location, data.azurerm_resource_group.main.location)

  runtime = merge({
    name    = "node"
    version = ""
  }, var.runtime)

  runtime_name = lower(local.runtime.name)

  # FIXME: create a data source to get list of supported runtimes and SKUs
  runtime_versions = {
    windows = {
      aspnet = ["4.7", "3.5"]
      node   = ["10.6", "10.0", "8.11", "8.10", "8.9", "8.5", "8.4", "8.1", "7.10", "6.12", "6.9", "6.5", "4.8", "0.12", "0.10", "0.8", "0.6"]
      php    = ["7.3", "7.2", "7.1", "7.0", "5.6"]
      python = ["3.6", "2.7"]
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
  linux_runtime_versions   = flatten([for k, v in local.runtime_versions.linux : v if k == local.runtime_name])
  windows_runtime_versions = flatten([for k, v in local.runtime_versions.windows : v if k == local.runtime_name])

  runtime_version = (
    local.runtime.version != "" ? local.runtime.version :
    length(local.linux_runtime_versions) > 0 ? local.linux_runtime_versions[0] :
    length(local.windows_runtime_versions) > 0 ? local.linux_runtime_versions[0] :
    ""
  )

  os_type = (
    contains(local.linux_runtime_versions, local.runtime_version) ? "linux" :
    contains(local.windows_runtime_versions, local.runtime_version) ? "windows" :
    lower(local.plan.os_type)
  )

  check_supported_runtime = local.supported_runtimes[local.os_type][local.runtime_name][local.runtime_version]

  sku_sizes = {
    "Free"             = ["F1", "Free"]
    "Shared"           = ["D1", "Shared"]
    "Basic"            = ["B1", "B2", "B3"]
    "Standard"         = ["S1", "S2", "S3"]
    "Premium"          = ["P1", "P2", "P3"]
    "PremiumV2"        = ["P1v2", "P2v2", "P3v2"]
    "PremiumContainer" = ["PC2", "PC3", "PC4"]
    "ElasticPremium"   = ["EP1", "EP2", "EP3"]
  }
  skus = flatten([
    for tier, sizes in local.sku_sizes : [
      for size in sizes : {
        tier = tier
        size = size
      }
    ]
  ])
  sku_tiers = { for sku in local.skus : sku.size => sku.tier }

  is_shared = contains(["F1", "FREE", "D1", "SHARED"], upper(local.plan.sku_size))

  always_on = local.is_shared ? false : true

  use_32_bit_worker_process = local.is_shared ? true : false

  dotnet_clr_versions = {
    "3.5" = "v2.0"
    "4.7" = "v4.0"
  }
  dotnet_framework_version = local.runtime_name == "aspnet" ? local.dotnet_clr_versions[local.runtime_version] : null

  php_version = local.os_type == "windows" && local.runtime_name == "php" ? local.runtime_version : null

  python_version = local.os_type == "windows" && local.runtime_name == "python" ? local.runtime_version : null

  linux_fx_version = local.os_type == "linux" ? format("%s|%s", upper(local.runtime.name), local.runtime_version) : null

  node_default_version = local.os_type == "windows" ? {
    WEBSITE_NODE_DEFAULT_VERSION = local.runtime_name == "node" ? local.runtime_version : "8.11.1"
  } : {}

  app_settings = merge(
    var.app_settings,
    local.secure_app_settings,
    local.node_default_version
  )

  ip_restrictions = [
    for prefix in var.ip_restrictions : {
      ip_address  = split("/", prefix)[0]
      subnet_mask = cidrnetmask(prefix)
    }
  ]

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

  auth = merge({
    enabled = false
    active_directory = {
      client_id     = ""
      client_secret = ""
    }
    token_store_enabled = true
  }, var.auth)

  identity = merge({
    enabled = true
    ids     = null
  }, var.identity)

  scaling = merge({
    enabled   = false
    min_count = 1
    max_count = 3
    rules = [
      {
        condition = "CpuPercentage > 75 avg 5m"
        scale     = "out 1"
      },
      {
        condition = "CpuPercentage < 30 avg 10m"
        scale     = "in 1"
      }
    ]
  }, var.scaling)

  scaling_rules = [
    for r in local.scaling.rules : merge({
      condition  = ""
      scale      = ""
      cooldown   = 5
      time_grain = "avg 1m"
    }, r)
  ]

  operator_conversion = {
    "="  = "Equals"
    "!=" = "NotEquals"
    ">"  = "GreaterThan"
    ">=" = "GreaterThanOrEqual"
    "<"  = "LessThan"
    "<=" = "LessThanOrEqual"
  }

  time_aggregation_conversion = {
    avg   = "Average"
    min   = "Minimum"
    max   = "Maximum"
    total = "Total"
    count = "Count"
  }

  scale_direction_conversion = {
    to  = "None"
    out = "Increase"
    in  = "Decrease"
  }

  statistic_conversion = {
    avg = "Average"
    min = "Min"
    max = "Max"
  }

  condition_pattern = "/^([\\w\\s]*)\\s([!=><]*)\\s(\\d*)\\s(avg|min|max|total|count)\\s(\\d*[d|h|m|s])$/"

  metric_triggers = [
    for r in local.scaling_rules : {
      metric_name        = replace(r.condition, local.condition_pattern, "$1")
      metric_resource_id = azurerm_app_service.main.app_service_plan_id
      time_grain         = format("PT%s", upper(split(" ", r.time_grain)[1]))
      statistic          = local.statistic_conversion[split(" ", r.time_grain)[0]]
      time_window        = format("PT%s", upper(replace(r.condition, local.condition_pattern, "$5")))
      time_aggregation   = local.time_aggregation_conversion[replace(r.condition, local.condition_pattern, "$4")]
      operator           = local.operator_conversion[replace(r.condition, local.condition_pattern, "$2")]
      threshold          = format("%d", replace(r.condition, local.condition_pattern, "$3"))
    }
  ]

  scale_pattern = "/^(to|out|in)\\s(\\d*)(%?)$/"

  scale_actions = [
    for r in local.scaling_rules : {
      direction = local.scale_direction_conversion[split(" ", r.scale)[0]]
      type = (
        split(" ", r.scale)[0] == "to" ?
        "ExactCount" :
        replace(r.scale, local.scale_pattern, "$3") != "" ?
        "PercentChangeCount" :
        "ChangeCount"
      )
      value    = replace(r.scale, local.scale_pattern, "$2")
      cooldown = format("PT%dM", r.cooldown)
    }
  ]

  client_affinity_enabled = local.scaling.enabled ? true : false

  storage_mounts = [
    for s in var.storage_mounts : merge({
      name           = ""
      account_name   = ""
      access_key     = ""
      share_name     = ""
      container_name = ""
      mount_path     = ""
    }, s)
  ]
}
