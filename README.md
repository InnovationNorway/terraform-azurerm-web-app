# Web App (Azure App Service)

Create Web App (App Service) in Azure.

## Example Usage

### Runtime (Use .NET Core 2.2)

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
    version = "2.2"
  }
}
```

### Source App Settings from Key Vault

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

### Access Restrictions (Restrict IPs)

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

### Scaling

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
    enabled = true
    max_count = 3
  }
}
```

## Arguments

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | The name of the web app. |
| `resource_group_name` | `string` | The name of an existing resource group to use for the web app. |
| `runtime` | `object` | The runtime to use for the web app. This should be a `runtime` object. |
| `plan` | `object` | The app service plan to use for the web app. This should be a `plan` object. |
| `app_settings` | `map` | A map of App Setttings for the web app. |
| `secure_app_settings` | `map` | A map of sensitive app settings. Uses Key Vault references as values for app settings. |
| `key_vault_id` | `string` | The ID of an existing Key Vault. Required if `secure_app_settings` is set. |
| `http2_enabled` | `bool` | Whether clients are allowed to connect over HTTP 2.0. Default: `true`. |
| `https_only` | `bool` | Redirect all traffic made to the web app using HTTP to HTTPS. Default: `false`. |
| `ftps_state` | `string` | Set the FTPS state value the web app. The options are: `AllAllowed`, `Disabled` and `FtpsOnly`. Default: `Disabled`. |
| `ip_restrictions` | `list` | A list of IP addresses in CIDR format specifying Access Restrictions. |
| `custom_hostnames` | `list` | List of custom hostnames to use for the web app. |
| `auth` | `object` | Auth settings for the web app. This should be `auth` object. |
| `identity` | `object` | Managed service identity properties. This should be `identity` object. |
| `storage_mounts` | `list` | List of storage mounts for the web app. |
| `tags` | `map` | A mapping of tags to assign to the web app. |

The `runtime` object accepts the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | The name of the runtime. The options are: `aspnet`, `dotnetcore`, `node`, `python`, `ruby`, `php`, `java`, `tomcat`, `wildfly`. Default: `node`. |
| `version` | `string` | The version of the runtime. |

The `plan` object accepts the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `id` | `string` | The ID of an existing app service plan. |
| `name` | `string` | The name of a new app service plan. |
| `sku_size` | `string` | The SKU size of a new app service plan. The options are: `F1`, `D1`, `B1`, `B2`, `B3`, `S1`, `S2`, `S3`, `P1v2`, `P2v2`, `P3v2`. Default: `F1`. |

The `sku_size` parameter can be one of the following:

| Size | Tier | Description |
| --- | --- | --- |
| `F1`, `Free` | Free | Free |
| `D1`, `Shared` | Shared | Shared |
| `B1`, `B2`, `B3` | Basic | Small, Medium, Large |
| `S1`, `S2`, `S3` | Standard | Small, Medium, Large |
| `P1v2`, `P2v2`, `P3v2` | PremiumV2 | Small, Medium, Large |

The `identity` object accepts the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `enabled` | `bool` | Whether managed service identity is enabled for the web app. Default: `true`. |
| `ids` | `list` | List of user managed identity IDs. |

The `auth` object accepts the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `enabled` | `bool` | Whether authentication is enabled for the web app. Default: `false`. |
| `token_store_enabled` | `bool` | Whether token store is enabled for the web app. Default: `true`. |
| `active_directory` | `object` | Azure Active Directory auth settings. This should be `active_directory` object. | 

The `active_directory` object accepts the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `client_id` | `string` | The ID of the Azure AD application. |
| `client_secret` | `string` | The password of the Azure AD Application. |

The `scaling` object accepts the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `enabled` | `bool` | Wheter scaling is enabled for the web app. Default: `false`. |
| `min_count` | `number` | The minimum number of instances. Default: `1`. |
| `max_count` | `number` | The maximum number of instances. Default: `3` |
| `rules` | `list` | List of scaling rules. This should be `rules` object. |

The `rules` object accepts the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `condition` | `string` | **Required**. The condition which triggers the scaling action. |
| `scale` | `string` | **Required**. The direction and amount to scale. |
| `cooldown` | `number` | The number of minutes that must elapse before another scaling event can occur. Default: `5`. |
| `time_grain` | `string` | The way metrics are polled across instances. Default: `avg 1m`. |

The `storage_mounts` object accepts the following keys:

 | Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | The identifier of the storage mount. |
| `account_name` | `string` | The name of the storage account. |
| `share_name` | `string` | The name of the file share.  |
| `container_name` | `string` | The name of the blob container. Either this or `share_name` should be specified, but not both. |
| `mount_path` | `string` | The path to mount the storage within the web app. |
