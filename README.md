# Web App (Azure App Service)

Create Web App (App Service) in Azure.

## Example Usage

### Set runtime

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

module "web_app" {
  source = "innovationnorway/web-app/azurerm"

  name = "example"

  resource_group_name = azurerm_resource_group.example.name


  runtime = {
    name    = "dotnetcore"
    version = "2.1"
  }
}
```

### Source Application Settings from Key Vault

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

module "web_app" {
  source = "innovationnorway/web-app/azurerm"

  name = "example"

  resource_group_name = azurerm_resource_group.example.name

  key_vault_id = azurerm_key_vault.example.id

  secure_app_settings = {
    MESSAGE = "Hello World!"
  }
}
```

### Configure IP restrictions

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

module "web_app" {
  source = "innovationnorway/web-app/azurerm"

  name = "example"

  resource_group_name = azurerm_resource_group.example.name

  ip_restrictions = ["192.168.3.4/32", "192.168.2.0/24"]
}
```

### Enable scaling

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

module "web_app" {
  source = "innovationnorway/web-app/azurerm"

  name = "example"

  resource_group_name = azurerm_resource_group.example.name

  scaling = {
    min_count = 1
    max_count = 3
  }
}
```

## Arguments

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | The name of the web app. |
| `resource_group_name` | `string` | The name of an existing resource group to use for the web app. |
| `app_settings` | `map` | A map of App Setttings for the web app. |
| `secure_app_settings` | `map` | Set sensitive app settings. Uses Key Vault references as values for app settings. |
| `plan` | `map` | A map of app service plan properties. |
| `key_vault_id` | `string` | The ID of an existing Key Vault. Required if `secure_app_settings` is set. |
| `ip_restrictions` | `list` | A list of IP addresses in CIDR format specifying Access Restrictions. |
| `tags` | `map` | A mapping of tags to assign to the web app. |

The `plan` object accepts the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `id` | `string` | The ID of an existing app service plan. |
| `name` | `string` | The name of a new app service plan. |
| `sku_size` | `string` | The SKU size of a new app service plan. The options are: `B1` (Basic Small), `B2` (Basic Medium), `B3` (Basic Large), `S1` (Standard Small), `S2` (Standard Medium), `S3` (Standard Large), `P1v2` (PremiumV2 Small), `P2v2` (PremiumV2 Medium), `P3v2` (PremiumV2 Large). Default: `B1`. |
| `os_type` | `string` | The operating system type. The options are: `linux`, `windows`. |

The `runtime` object must have the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | The name of the runtime. The options are: `aspnet`, `dotnetcore`, `node`, `python`, `ruby`, `php`, `java`, `tomcat`, `wildfly`. Default: `node`. |
| `version` | `string` | The version of the runtime. |


The `scaling` object accepts the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `enabled` | `bool` | Whether scaling is enabled or not. |
| `min_count` | `number` | The minimum number of instances. Default: `1`. |
| `max_count` | `number` | The maximum number of instances. Default: `3`.  |
| `rules` | `list` | List of autoscale rules. This should be `scaling` objects. |
